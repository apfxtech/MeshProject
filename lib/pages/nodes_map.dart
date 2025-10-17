// lib/pages/map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/node.dart';

class MapView extends StatelessWidget {
  final List<Node> nodes;

  const MapView({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    final markers = nodes
        .where((n) => n.latitude != null && n.latitude != 0 && n.longitude != null && n.longitude != 0)
        .map((n) => Marker(
              point: LatLng(n.latitude!, n.longitude!),
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Icon(Icons.location_pin, color: Colors.red, size: 40),
                  Text(
                    n.shortName ?? n.longName ?? 'Node ${n.nodeNum.toRadixString(16)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ))
        .toList();

    LatLng center = markers.isNotEmpty ? markers.first.point : LatLng(0, 0);
    double zoom = markers.isNotEmpty ? 10 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Карта узлов')),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: zoom),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.aegis_app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}