// lib/pages/home/home.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Добавлен импорт для go_router

import '../../widgets/appbar.dart';
import '../../widgets/split_or_tabs.dart';

import '../../services/meshtastic.dart';
import '../../data/models/chat.dart';
import '../../data/repo/chats.dart'; 

import 'nodes.dart';
import 'chats.dart';
import 'chat.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Widget> _tabs = [
    const Tab(text: 'Nodes'),
    const Tab(text: 'Chats'),
    const Tab(text: 'Chat'),
  ];

  late MeshtasticClient radio_client;
  bool _isInitialized = false;
  bool _isConnecting = false;
  ConnectionStatus? _connectionStatus;
  late TabController _tabController;
  late ScrollController _chatScrollController;
  bool _showChatFab = false; 

  int? _selectedChatId;
  String? _selectedChatTitle;

  final GlobalKey<ChatsViewState> _chatsKey = GlobalKey<ChatsViewState>();
  final GlobalKey<NodesViewState> _nodesKey = GlobalKey<NodesViewState>();

  IconData? _currentLoadingIcon;

  String? _phase = 'connecting';
  bool _isOwnNodeReceived = false;
  int _receivedChannels = 0;
  int _maxChannels = 8;
  int _receivedConfigs = 0;
  int _maxConfigs = 10;
  int _receivedModuleConfigs = 0;
  int _maxModuleConfigs = 13;
  int get _receivedNodes => radio_client.nodes.length;
  int get _maxNodes => radio_client.myNodeInfo?.nodedbCount ?? 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _chatScrollController = ScrollController();
    _chatScrollController.addListener(_updateChatFabVisibility);
    _initializeClient();
  }

  void _updateChatFabVisibility() {
    if (_tabController.index != 2) return;
    final maxScroll = _chatScrollController.position.maxScrollExtent;
    final currentScroll = _chatScrollController.offset;
    final tolerance = 50.0;
    final isAtBottom = currentScroll >= (maxScroll - tolerance);
    if (_showChatFab != !isAtBottom) {
      setState(() {
        _showChatFab = !isAtBottom;
      });
    }
  }

  Future<void> _initializeClient() async {
    radio_client = MeshtasticOneClient().get();
    try {
      await radio_client.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      radio_client.connectionStream.listen((status) {
        if (mounted) {
          setState(() {
            _connectionStatus = status;
          });
        }
      });

      radio_client.nodeStream.listen((node) {
        if (radio_client.isConfigured) return; 
        if (mounted) {
          setState(() {});
        }
        if (!_isOwnNodeReceived) {
          _isOwnNodeReceived = true;
          _maxChannels = 8;
          _phase = 'channels';
          _currentLoadingIcon = Icons.chat;
          _receivedChannels = 0;
        } else if (_phase == 'nodes') {
          setState(() {
            _currentLoadingIcon = Icons.cell_tower;
          });
        }
      });

      radio_client.channelStream.listen((channel) async {
        if (channel.role.toString() != 'DISABLED') {
          String title = channel.settings.name;
          if (title.isEmpty && channel.role.toString() == 'PRIMARY') {
            title = 'Global';
          }
          String source = 'c:${channel.index}';
          String key = base64Encode(channel.settings.psk);
          
          Chat? existingChat = await ChatsRepository.getBySource(source);
          if (existingChat == null) {
            Chat newChat = Chat(
              title: title,
              source: source,
              key: key,
            );
            await ChatsRepository.add(newChat);
            _chatsKey.currentState?.loadChats();
          }
        }
        if (radio_client.isConfigured) return;
        if (_phase == 'channels') {
          _receivedChannels++;
          if (_receivedChannels >= _maxChannels) {
            _phase = 'configs';
            _currentLoadingIcon = Icons.settings;
            _receivedConfigs = 0;
          }
          setState(() {});
        }
      });

      radio_client.configPartStream.listen((config) {
        if (radio_client.isConfigured) return; 
        if (_phase == 'configs') {
          _receivedConfigs++;
          if (_receivedConfigs >= _maxConfigs) {
            _phase = 'moduleConfigs';
            _currentLoadingIcon = Icons.public;
            _receivedModuleConfigs = 0;
          }
          setState(() {});
        }
      });

      radio_client.moduleConfigPartStream.listen((moduleConfig) {
        if (radio_client.isConfigured) return; 
        if (_phase == 'moduleConfigs') {
          _receivedModuleConfigs++;
          if (_receivedModuleConfigs >= _maxModuleConfigs) {
            _phase = 'nodes';
            _currentLoadingIcon = Icons.cell_tower;
            _receivedModuleConfigs = 0;
          }
          setState(() {});
        }
      });

      radio_client.packetStream.listen((packet) async {
        if (packet.isTextMessage) {
          await handleIncomingMessage(radio_client, packet);
          _chatsKey.currentState?.loadChats();
        }
      });

      await _connectToDevice();
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _connectToDevice() async {
    if (_isConnecting || !_isInitialized) return;

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Включите Bluetooth для подключения.')),
        );
        setState(() {
          _isConnecting = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isConnecting = true;
      });
    }

    bool deviceFound = false;
    await for (final device in radio_client.scanForDevices(timeout: Duration(seconds: 30))) {
      if (!deviceFound) {
        deviceFound = true;
        try {
          await radio_client.connectToDevice(device);
          await Future.delayed(Duration(seconds: 5));
        } catch (e) {}
        break;
      }
    }

    if (!deviceFound) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      radio_client.dispose();
    } catch (e) {}
    _chatScrollController.removeListener(_updateChatFabVisibility);
    _chatScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tabs[2] = Tab(text: _selectedChatTitle ?? 'Chat');
    final List<Widget> _children = [
      NodesView(
        key: _nodesKey,
        client: radio_client,
        isClientInitialized: _isInitialized,
        onChatCreated: (int id) async {
          _tabController.animateTo(1);
          _chatsKey.currentState?.loadChats();
          _selectedChatId = id;
          final chat = await ChatsRepository.getChat(id);
          _selectedChatTitle = chat?.title ?? 'Chat';
          setState(() {});
        },
      ),
      ChatsView(
        key: _chatsKey,
        client: radio_client,
        isClientInitialized: _isInitialized,
        selectedChatId: _selectedChatId,
        onChatSelected: (int id) async {
          _selectedChatId = id;
          final chat = await ChatsRepository.getChat(id);
          _selectedChatTitle = chat?.title ?? 'Chat';
          setState(() {});
        },
        onDeleteChat: (int id) {
          if (_selectedChatId == id) {
            _selectedChatId = null;
            _selectedChatTitle = null;
          }
          setState(() {});
        },
      ),
      ChatView(
        client: radio_client,
        isClientInitialized: _isInitialized,
        scrollController: _chatScrollController,
        selectedChatId: _selectedChatId
      ),
    ];

    bool showProgress = !radio_client.isConfigured &&
        (_isConnecting ||
            _connectionStatus?.state == MeshtasticConnectionState.connecting ||
            _connectionStatus?.state == MeshtasticConnectionState.configuring);

    double? progressValue;
    if (_phase == 'connecting') {
      progressValue = null;
    } else if (_phase == 'channels') {
      progressValue = _receivedChannels / _maxChannels.clamp(1, double.infinity);
    } else if (_phase == 'configs') {
      progressValue = _receivedConfigs / _maxConfigs.clamp(1, double.infinity);
    } else if (_phase == 'moduleConfigs') {
      progressValue = _receivedModuleConfigs / _maxModuleConfigs.clamp(1, double.infinity);
    } else if (_phase == 'nodes') {
      int effectiveMaxNodes = (_maxNodes - 1).clamp(0, double.infinity).toInt();
      int effectiveReceivedNodes = (_receivedNodes - 1).clamp(0, effectiveMaxNodes);
      progressValue = effectiveMaxNodes > 0 ? effectiveReceivedNodes / effectiveMaxNodes : 1.0;
    } else {
      progressValue = null;
    }

    if (!showProgress) {
      _currentLoadingIcon = null;
    }

    Widget? fab;
    switch (_tabController.index) {
      case 0:
        fab = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'map',
              onPressed: () {
                final nodes = _nodesKey.currentState?.nodes ?? [];
                context.push('/map', extra: nodes);
              },
              child: const Icon(Icons.map),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'refresh',
              onPressed: _connectToDevice,
              child: const Icon(Icons.refresh),
            ),
          ],
        );
        break;
      case 1:
        fab = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'cards',
              onPressed: () => _chatsKey.currentState?.createNewChatWithCards(),
              child: const Icon(Icons.view_module),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'list',
              onPressed: () => _chatsKey.currentState?.createNewChatWithList(),
              child: const Icon(Icons.list),
            ),
          ],
        );
        break;
      case 2: 
        if (_showChatFab) {
          fab = FloatingActionButton(
            onPressed: () {
              _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: const Icon(Icons.arrow_downward),
            tooltip: 'Прокрутить вниз',
          );
        }
        break;
    }

    return Scaffold(
      appBar: AegisAppBar(
        longName: radio_client.localUser?.longName,
        shortName: radio_client.localUser?.shortName,
        isLoading: showProgress,
        loadingIcon: _currentLoadingIcon,
      ),
      body: Column(
        children: [
          if (showProgress) LinearProgressIndicator(value: progressValue),
          Expanded(
            child: SplitOrTabs(
              tabs: _tabs,
              children: _children,
              controller: _tabController,
            ),
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}