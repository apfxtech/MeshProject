// lib/pages/home/nodes.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/meshtastic.dart';
import '../../../data/repo/nodes.dart';
import '../../../data/models/node.dart';
import '../../widgets/avatars.dart';
import '../../data/repo/chats.dart';
import '../../data/models/chat.dart';
import '../../widgets/search.dart';

class NodesView extends StatefulWidget {
  final MeshtasticClient client;
  final bool isClientInitialized;
  final Function(int)? onChatCreated;

  const NodesView({
    super.key,
    required this.client,
    this.isClientInitialized = false,
    this.onChatCreated,
  });

  @override
  State<NodesView> createState() => NodesViewState();
}

class NodesViewState extends State<NodesView> {
  List<Node> _nodes = [];
  List<Node> get nodes => _nodes;
  StreamSubscription? _nodeSubscription;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialNodes();
    if (widget.isClientInitialized) {
      _setupNodeListener();
    }
  }

  @override
  void didUpdateWidget(covariant NodesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClientInitialized && !oldWidget.isClientInitialized) {
      _setupNodeListener();
    }
  }

  Future<void> _loadInitialNodes() async {
    final savedNodes = await NodeRepository.getAll();
    if (mounted) {
      setState(() {
        _nodes = savedNodes;
      });
    }
  }

  void _setupNodeListener() {
    if (_nodeSubscription != null) return;
    _nodeSubscription = widget.client.nodeStream.listen((node) async {
      final nodeModel = Node(
        nodeNum: node.num,
        longName: node.longName,
        shortName: node.shortName,
        hwModel: node.hwModel,
        isLicensed: node.isLicensed,
        role: node.role,
        latitude: node.latitude,
        longitude: node.longitude,
        altitude: node.altitude,
        batteryLevel: node.batteryLevel,
        voltage: node.voltage,
        channelUtilization: node.channelUtilization,
        airUtilTx: node.airUtilTx,
        channel: node.channel,
        lastHeard: node.lastHeard,
        snr: node.snr,
      );
      await NodeRepository.add(nodeModel);
      final existingIndex = _nodes.indexWhere((n) => n.nodeNum == nodeModel.nodeNum);
      if (existingIndex != -1) {
        _nodes[existingIndex] = nodeModel;
      } else {
        _nodes.add(nodeModel);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nodeSubscription?.cancel();
    super.dispose();
  }

  String _timeAgo(DateTime? lastHeard) {
    if (lastHeard == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(lastHeard);
    final minutes = diff.inMinutes;
    if (minutes < 1) return 'now';
    if (minutes < 60) return '${minutes}м';
    final hours = diff.inHours;
    if (hours < 24) return '${hours}ч';
    final days = diff.inDays;
    if (days <= 30) return '${days}д';
    return 'давно';
  }

  Future<void> _createChatForNode(Node node) async {
    final myNodeNum = widget.client.myNodeInfo?.myNodeNum;
    if (myNodeNum == null) return;

    final assistant = 'n:${node.nodeNum.toRadixString(16)}';
    final source = 'n:${myNodeNum.toRadixString(16)}';

    final existingChat = await ChatsRepository.getBySourceAndAssistant(source, assistant);
    if (existingChat != null) {
      widget.onChatCreated?.call(existingChat.id);
      return;
    }

    final newChat = Chat(
      title: node.longName ?? 'Node ${node.nodeNum.toRadixString(16)}',
      assistant: assistant,
      source: source,
      key: 'AQ==',
      temperature: 0.7,
      top_p: 0.9,
      max_tokens: 256,
    );

    final id = await ChatsRepository.add(newChat);
    widget.onChatCreated?.call(id);
  }

  Widget _buildNodesList() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_nodes.isEmpty) {
      return const Center(child: Text('Нет нод в базе данных'));
    }

    final lowerQuery = _searchQuery.toLowerCase();
    final filteredNodes = _nodes.where((node) {
      final longNameLower = node.longName?.toLowerCase() ?? '';
      final shortNameLower = node.shortName?.toLowerCase() ?? '';
      return longNameLower.contains(lowerQuery) || shortNameLower.contains(lowerQuery);
    }).toList();

    return Column(
      children: [
        SearchWidget(
          labelText: 'Поиск узлов:',
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredNodes.length,
            itemBuilder: (context, index) {
              final node = filteredNodes[index];
              String avatarName = node.longName ?? 'Node ${node.nodeNum.toRadixString(16)}';
              if (node.shortName != null && node.shortName!.isNotEmpty) {
                avatarName += ' (${node.shortName})';
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {},
                    onLongPress: () => _createChatForNode(node),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AvatarWidget(
                            text: avatarName,
                            size: 48.0,
                            backgroundColor: colorScheme.secondaryContainer,
                            foregroundColor: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 14.0),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 45.0,
                                height: 45.0,
                                child: CircularProgressIndicator(
                                  value: node.batteryLevel != null ? (node.batteryLevel! / 100.0).clamp(0.0, 1.0) : 0.0,
                                  backgroundColor: colorScheme.surface,
                                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                                ),
                              ),
                              if (node.batteryLevel != null)
                                if (node.batteryLevel! > 100)
                                  Icon(Icons.bolt, color: colorScheme.onSecondaryContainer, size: 22.0)
                                else
                                  Text('${node.batteryLevel}%',
                                      style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 11.0))
                              else
                                Text('N/A', style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 11.0)),
                            ],
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.longName ?? 'Node ${node.nodeNum.toRadixString(16)}',
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    Text('(${node.shortName ?? 'N/A'})',
                                        style: TextStyle(color: colorScheme.onSecondaryContainer)),
                                    const SizedBox(width: 12.0),
                                    Text('SNR: ${node.snr}', style: TextStyle(color: colorScheme.onSecondaryContainer)),
                                    const SizedBox(width: 12.0),
                                    Text('Last: ${_timeAgo(node.lastHeard)}',
                                        style: TextStyle(color: colorScheme.onSecondaryContainer)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildNodesList();
  }
}