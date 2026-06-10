import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_service.dart'; // Sesuaikan path jika error

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final StreamController<RemoteMessage> onMessageStream = StreamController<RemoteMessage>.broadcast();
  
  static Future<void> initialize() async {
    // 1. Minta Izin ke User (Memunculkan Pop-up "Allow Notifications")
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User mengizinkan notifikasi!');
      
      // 2. Ambil FCM Token HP ini
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token HP ini: $token');
      
      // 3. Kirim Token ke Laravel
      if (token != null) {
        await ApiService().sendFcmTokenToServer(token);
      }

      // Jika token berubah suatu saat, otomatis kirim ulang ke Laravel
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        ApiService().sendFcmTokenToServer(newToken);
      });
    }

    // 4. Setup Tampilan Notifikasi saat aplikasi sedang dibuka (Foreground)
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('ic_stat_notification');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    await _localNotificationsPlugin.initialize(settings: initSettings);

    // 5. Tangkap Notifikasi yang masuk saat aplikasi sedang dimainkan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
        onMessageStream.add(message);
      }
    });
  }

  static void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'caldera_channel_id', // ID Channel
      'Caldera Notifications', // Nama Channel di setting HP
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformDetails,
    );
  }
}