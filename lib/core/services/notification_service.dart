import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _repository;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._repository);

  Future<void> initialize() async {
    // 1. Pedir permissão (iOS e Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('Usuário permitiu notificações');
    }

    // 1.1 Configurar como as notificações aparecem com o app aberto (iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, // Garante que o banner apareça
      badge: true,
      sound: true,
    );

    // 2. Configurar Notificações Locais (para popups em foreground no Android)
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Na versão 20.0.0, os parâmetros são nomeados
    await _localNotifications.initialize(settings: initializationSettings);

    // 3. Listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
  }

  Future<void> saveDeviceToken(String userId) async {
    try {
      // No iOS, se for um simulador ou se o token APNS não estiver pronto, getToken() falha.
      // Adicionamos um try-catch para evitar crash.
      String? token = await _fcm.getToken();

      if (token != null) {
        if (kDebugMode) print("FCM Token: $token");
        await _repository.saveToken(userId, token);
      }

      // Escutar refresh de token
      _fcm.onTokenRefresh.listen((newToken) {
        _repository.saveToken(userId, newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print(
          "Aviso: Não foi possível obter o token FCM (pode ser o simulador iOS): $e",
        );
      }
    }
  }

  Future<void> subscribeToTenantTopics(String tenantSlug, String env) async {
    try {
      // Tópico para todos os usuários do tenant no ambiente específico
      // Ex: tucttx_dev_all
      final topic = '${tenantSlug}_${env}_all';
      await _fcm.subscribeToTopic(topic);
      if (kDebugMode) print("Inscrito no tópico: $topic");
    } catch (e) {
      if (kDebugMode) print("Erro ao se inscrever no tópico: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    // No iOS, configuramos setForegroundNotificationPresentationOptions para o sistema cuidar do banner.
    // Para Android, usamos o flutter_local_notifications manualmente.
    if (notification != null &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    // Lógica para quando o usuário clica na notificação
    if (kDebugMode) print("Notificação clicada: ${message.data}");
  }
}
