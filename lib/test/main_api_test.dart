import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Демо локальных уведомлений',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int id = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');  // Иконка в drawable

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Создание канала для Android
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      'text_channel_id',  // ID канала
      'Текстовая нотификация',  // Название канала
      description: 'Канал для текстовых уведомлений',
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> _showTextNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'text_channel_id',
      'Текстовая нотификация',
      channelDescription: 'Канал для текстовых уведомлений',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id++,
      'Заголовок уведомления',
      'Это тело текстового уведомления.',
      notificationDetails,
      payload: 'Данные для обработки',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Локальные уведомления'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showTextNotification,
          child: const Text('Отправить текстовое уведомление'),
        ),
      ),
    );
  }
}