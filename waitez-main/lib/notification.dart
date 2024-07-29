import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterLocalNotification {
  FlutterLocalNotification._();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    final bool? result = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Notification tapped logic here
      },
    );

    if (result != null && result) {
      print('Notification initialized successfully');
    } else {
      print('Notification initialization failed');
    }
  }

  static Future<void> showNotification(String title, String body) async {
    // 알림을 보내기 전에 appAlert 상태를 확인
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? appAlert = prefs.getBool('appAlert') ?? false;

    if (appAlert) {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'channel description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      try {
        await flutterLocalNotificationsPlugin.show(
            0, title, body, notificationDetails);
        print('Notification shown successfully');
      } catch (e) {
        print('Error showing notification: $e');
      }
    } else {
      print("App alerts are turned off. Notification not sent.");
    }
  }
}

class NotificationService {
  static Future<void> sendSmsNotification(
      String message, List<String> recipients) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool smsAlert = prefs.getBool('smsAlert') ?? false;

    if (smsAlert) {
      String _message = Uri.encodeComponent(message);
      String _recipients = recipients.join(',');
      String _url = 'sms:$_recipients?body=$_message';

      if (await canLaunch(_url)) {
        await launch(_url);
      } else {
        throw 'Could not launch $_url';
      }
    } else {
      print("SMS Alert is disabled. No SMS sent.");
    }
  }
}
