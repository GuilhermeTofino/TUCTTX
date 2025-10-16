import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

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

    // **[CORREÇÃO]** Habilita a exibição de notificações quando o app está em primeiro plano (iOS).
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, // Exibe o alerta/banner
      badge: true, // Atualiza o ícone do app com um número
      sound: true, // Toca o som da notificação
    );

    // Apenas para iOS, aguarda o token APNS ficar pronto para evitar race condition.
    if (Platform.isIOS) {
      await _firebaseMessaging.getAPNSToken();
    }

    // Obter Token FCM (pode ser salvo no banco de dados)
    final String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Configurar notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'canal_notificacao',
      'Canal de Notificação',
      channelDescription: 'Canal para exibir notificações do app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      sound: 'default.wav',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // ID único
      title,
      body,
      platformChannelSpecifics,
    );
  }
}