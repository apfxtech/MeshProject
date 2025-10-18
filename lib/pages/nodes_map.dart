// lib/pages/map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:async';

import '../../../data/models/node.dart';
import '../widgets/avatars.dart';

// TODO: класторизатор не правельно сумирует при больших маштабах

class _NodeCluster {
  final LatLng center;
  final List<Node> nodes;
  final double radius;

  _NodeCluster({
    required this.center,
    required this.nodes,
    this.radius = 50000, // в метрах
  });

  bool contains(Node node) {
    if (node.latitude == null || node.longitude == null) return false;
    final distance = const Distance().as(
      LengthUnit.Meter,
      LatLng(node.latitude!, node.longitude!),
      center,
    );
    return distance <= radius;
  }
}

class MapView extends StatefulWidget {
  final List<Node> nodes;

  const MapView({super.key, required this.nodes});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late MapController _mapController;
  double _currentZoom = 10;
  LatLng _currentCenter = const LatLng(0, 0);
  List<_NodeCluster> _allClusters = [];
  List<Marker> _visibleMarkers = [];
  bool _isInitialized = false;
  
  Timer? _debounceTimer;
  double _lastProcessedZoom = 10;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeClusters();
  }

  Future<void> _initializeClusters() async {
    final clusters = await _clusterNodesAsync(_currentZoom);
    if (mounted) {
      setState(() {
        _allClusters = clusters;
        _isInitialized = true;
        _lastProcessedZoom = _currentZoom;
      });
      _updateVisibleMarkers();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<_NodeCluster>> _clusterNodesAsync(double zoom) async {
    final validNodes = widget.nodes
        .where((n) =>
            n.latitude != null &&
            n.latitude != 0 &&
            n.longitude != null &&
            n.longitude != 0)
        .toList();

    if (validNodes.isEmpty) return [];

    // Радиус кластеризации в километрах - размер 2 маркеров
    // Уменьшается с зумом для большей детализации
    final radiusKm = 50.0 / pow(2, (zoom - 5).clamp(0, 10)).toDouble();
    final radiusMeters = radiusKm * 1000;

    var clusters = <_NodeCluster>[];
    final processedNodes = <Node>{};

    // Первая фаза: создаём кластеры для каждого ноды
    for (final node in validNodes) {
      if (processedNodes.contains(node)) continue;

      final cluster = _NodeCluster(
        center: LatLng(node.latitude!, node.longitude!),
        nodes: [node],
        radius: radiusMeters,
      );

      for (final otherNode in validNodes) {
        if (otherNode != node &&
            !processedNodes.contains(otherNode) &&
            cluster.contains(otherNode)) {
          cluster.nodes.add(otherNode);
          processedNodes.add(otherNode);
        }
      }

      clusters.add(cluster);
      processedNodes.add(node);
    }

    // Вторая фаза: объединяем близкие кластеры
    var merged = true;
    while (merged) {
      merged = false;
      for (int i = 0; i < clusters.length; i++) {
        for (int j = i + 1; j < clusters.length; j++) {
          final distance = const Distance().as(
            LengthUnit.Meter,
            clusters[i].center,
            clusters[j].center,
          );

          if (distance <= radiusMeters * 2) {
            // Объединяем кластеры - используем Map по nodeNum для дедупликации
            final mergedNodesMap = <int, Node>{};
            for (final node in clusters[i].nodes) {
              mergedNodesMap[node.nodeNum] = node;
            }
            for (final node in clusters[j].nodes) {
              mergedNodesMap[node.nodeNum] = node;
            }
            final mergedNodes = mergedNodesMap.values.toList();
            
            final centerLat = mergedNodes.fold<double>(
                  0,
                  (sum, n) => sum + (n.latitude ?? 0),
                ) /
                mergedNodes.length;
            final centerLng = mergedNodes.fold<double>(
                  0,
                  (sum, n) => sum + (n.longitude ?? 0),
                ) /
                mergedNodes.length;

            clusters[i] = _NodeCluster(
              center: LatLng(centerLat, centerLng),
              nodes: mergedNodes,
              radius: radiusMeters,
            );

            clusters.removeAt(j);
            merged = true;
            break;
          }
        }
        if (merged) break;
      }
    }

    return clusters;
  }

  bool _isWithinBounds(LatLng point) {
    // Вычисляем видимую область с буфером
    final zoom = _currentZoom;
    final metersPerPixel = 40075000 / (256 * pow(2, zoom).toDouble());

    // Примерно 800x600 пикселей видимой области + буфер
    final visibleWidthMeters = 1200 * metersPerPixel;
    final visibleHeightMeters = 1000 * metersPerPixel;

    // Конвертируем в градусы (примерно)
    final latDelta = visibleHeightMeters / 111000;
    final lngDelta = visibleWidthMeters /
        (111000 * cos((_currentCenter.latitude * pi) / 180));

    return point.latitude >= _currentCenter.latitude - latDelta &&
        point.latitude <= _currentCenter.latitude + latDelta &&
        point.longitude >= _currentCenter.longitude - lngDelta &&
        point.longitude <= _currentCenter.longitude + lngDelta;
  }

  void _updateVisibleMarkers() {
    final markers = <Marker>[];
    final colorScheme = Theme.of(context).colorScheme;

    for (final cluster in _allClusters) {
      // Пропускаем маркеры за экраном
      if (!_isWithinBounds(cluster.center)) continue;

      if (cluster.nodes.length == 1) {
        // Одиночный узел
        final node = cluster.nodes.first;
        markers.add(
          Marker(
            point: cluster.center,
            width: 60,
            height: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarWidget(
                  icon: node.isReceived ?? false
                      ? Icons.satellite_alt_rounded
                      : Icons.public,
                  size: 40,
                  border: true,
                ),
                if (node.shortName != null || node.longName != null)
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.shortName ?? node.longName ?? '',
                        style: const TextStyle(fontSize: 9, color: Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        // Кластер
        markers.add(
          Marker(
            point: cluster.center,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                _mapController.move(cluster.center, _currentZoom + 2);
              },
              child: AvatarWidget(
                text: cluster.nodes.length.toString(),
                size: 50,
                backgroundColor: colorScheme.onSecondaryContainer,
                foregroundColor: colorScheme.secondaryContainer,
                border: true,
              ),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _visibleMarkers = markers;
      });
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentCenter = camera.center;
    final newZoom = camera.zoom;
    _updateVisibleMarkers();

    // Дебаунс пересчёта кластеризации: только если зум изменился значительно
    _debounceTimer?.cancel();

    if ((newZoom - _lastProcessedZoom).abs() >= 0.3) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _currentZoom = newZoom;
        _initializeClusters();
      });
    } else {
      _currentZoom = newZoom;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Карта узлов')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final center = _allClusters.isNotEmpty
        ? _allClusters.first.center
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Карта узлов')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: _currentZoom,
          minZoom: 2,
          maxZoom: 18,
          onPositionChanged: _onPositionChanged,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.aegis_app',
          ),
          MarkerLayer(markers: _visibleMarkers),
        ],
      ),
    );
  }
}