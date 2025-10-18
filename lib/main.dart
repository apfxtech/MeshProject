// lib/main.dart
import 'package:aegis_open_network/data/models/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'package:tostore/tostore.dart' hide LogLevel;

import './theme.dart';
import './widgets/appbar.dart';
import './pages/home/home.dart';
//import './pages/create_bot_page.dart';
import './pages/nodes_map.dart';
import './data/repo/nodes.dart' as nodes;
import './data/repo/chats.dart' as chats;
import 'data/repo/users.dart' as users;
import './services/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AegisApp());
}

class AegisApp extends StatefulWidget {
  const AegisApp({super.key});

  @override
  State<AegisApp> createState() => _AegisAppState();
}

class _AegisAppState extends State<AegisApp> {
  bool _initialized = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _initAsync() async {
  try {
    await NotificationService.initialize(defaultIcon: 'mail_i', onNotificationClick: (response) {debugPrint('Уведомление кликнуто: ${response.payload}');});
    
    final allSchemas = [
      nodes.nodesSchema,
      chats.chatsSchema,
      chats.messagesSchema,
      users.usersSchema,
    ];
    
    final db = ToStore(schemas: allSchemas);
    await db.initialize();
    await db.createTables(allSchemas);
    
    nodes.NodeRepository.init(db);
    chats.ChatsRepository.init(db);
    users.UsersRepository.init(db);

    await FlutterBluePlus.setLogLevel(LogLevel.none);
    await Future.delayed(Duration(seconds: 1));
  } catch (e, st) {
    debugPrint('Ошибка при инициализации: $e\n$st');
  } finally {
    if (mounted) setState(() => _initialized = true);
  }
}

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme =
            (lightDynamic ?? const ColorScheme.light()).harmonized();
        final darkScheme = (darkDynamic ??
                const ColorScheme.dark(brightness: Brightness.dark))
            .harmonized();

        final themeLight = buildTheme(lightScheme);
        final themeDark = buildTheme(darkScheme);

        final router = GoRouter(
          navigatorKey: _navigatorKey,
          initialLocation: '/',
          redirect: (context, state) {
            final location = state.uri.toString();
            if (!_initialized && location != '/loading') {
              return '/loading';
            }
            if (_initialized && location == '/loading') {
              return '/';
            }
            return null;
          },
          routes: [
            GoRoute(
              path: '/loading',
              builder: (context, state) => Scaffold(
                appBar: const AegisAppBar(
                  loadingIcon: Icons.bluetooth_disabled,
                  isLoading: true,
                ),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Загрузка данных..."),
                    ],
                  ),
                ),
              ),
            ),
            GoRoute(
              name: 'home',
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              name: 'map',
              path: '/map',
              builder: (context, state) {
                final nodes = state.extra as List<Node>? ?? [];
                return MapView(nodes: nodes);
              },
            ),
            //  GoRoute(
            //   name: 'create-bot',
            //   path: '/create-bot',
            //   builder: (context, state) {
            //     final initialTitle = state.extra as String? ?? '';
            //     return CreateBotPage(initialTitle: initialTitle); 
            //   },
            // ),
          ],
        );

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: themeLight,
          darkTheme: themeDark,
          themeMode: ThemeMode.system,
        );
      },
    );
  }
}