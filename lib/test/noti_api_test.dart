import 'dart:io';  // Для Platform.isAndroid

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse notificationResponse) async {
  debugPrint('Фоновое уведомление получено: ${notificationResponse.payload}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static int _id = 0;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('mail_i');  // Требует app_icon.png в drawable

    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        debugPrint('Уведомление кликнуто: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    // Создание канала (только Android)
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'text_channel_id',
        'Текстовая нотификация',
        description: 'Канал для текстовых уведомлений',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Запрос разрешений (только Android)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> sendTextNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'text_channel_id',
        'Текстовая нотификация',
        channelDescription: 'Канал для текстовых уведомлений',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        _id++,
        title,
        body,
        details,
        payload: payload ?? 'Данные для обработки',
      );
    } catch (e) {
      debugPrint('Ошибка показа уведомления: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Демо уведомлений (Android)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _showTextNotification() async {
    await NotificationService.sendTextNotification(
      title: 'Заголовок уведомления',
      body: 'Это тело текстового уведомления.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Локальные уведомления (Android)')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showTextNotification,
          child: const Text('Отправить уведомление'),
        ),
      ),
    );
  }
}