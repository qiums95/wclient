import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:wclient/main.dart';
import 'package:wclient/ui/chat_page.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// 初始化通知服务
  Future<void> init() async {
    // Android 配置：使用应用默认的启动图标
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS 配置：申请权限
    const DarwinInitializationSettings darwinInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
      macOS: darwinInitSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payloadChatId = response.payload;
        if (payloadChatId != null && payloadChatId.isNotEmpty) {
          globalNavKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ChatPage(chatId: payloadChatId),
            ),
          );
        }
      },
    );

    // Android 13 及以上需要动态申请通知权限
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// 触发一条新消息通知
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // 安卓频道的配置
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'wechat_message_channel',
      '新消息通知',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true),
    );

    await _plugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}