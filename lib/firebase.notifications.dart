import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotifications {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Permissão negada para notificações.');
      return;
    }

    // Obter Token FCM (pode ser salvo no banco de dados)
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Configurar notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Quando o app estiver em **foreground** (ativo)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Mensagem recebida no app: ${message.notification?.title}");

      if (message.notification != null) {
        _showNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
        );
      }
    });

    // Quando o app for aberto por uma notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Usuário clicou na notificação: ${message.notification?.title}");
    });
  }

  static Future<void> _showNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'canal_notificacao',
      'Canal de Notificação',
      channelDescription: 'Canal para exibir notificações do app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, // ID da notificação
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
