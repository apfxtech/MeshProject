import 'dart:io'; // Для Platform.isAndroid

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(
  NotificationResponse notificationResponse,
) async {
  debugPrint('Фоновое уведомление получено: ${notificationResponse.payload}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static int _id = 0;

  static Future<void> initialize({
    required String defaultIcon,
    required void Function(NotificationResponse) onNotificationClick,
  }) async {
    final AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(defaultIcon);
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationClick,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

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
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> sendTextNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'text_channel_id',
            'Текстовая нотификация',
            channelDescription: 'Канал для текстовых уведомлений',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

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
