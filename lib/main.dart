import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as dev;
import 'package:app_tenda/app.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/services/firebase_remote_configs.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_tenda/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_tenda/core/services/layout_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode e PlatformDispatcher

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa o Firebase apenas se necessário em background
  await Firebase.initializeApp(options: FirebaseRemoteConfigs.currentOptions);
  print("Mensagem em background recebida: ${message.messageId}");
}

void main() async {
  try {
    // Garante que os bindings do Flutter estejam prontos
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR', null);
    await dotenv.load(fileName: ".env");

    // 1. Captura variáveis de ambiente
    // Não existe mais --dart-define=TENANT: o app é único (EloApp) e a casa
    // do usuário só é conhecida depois do login, resolvida via
    // FirebaseAuthRepository (ver _resolveTenantForUser).
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');

    // 2. Instancia a configuração global (ainda sem tenant)
    final env = envString == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;
    AppConfig.instantiate(environment: env);

    // 3. Inicializa Service Locator (Injeção de Dependências)
    await setupServiceLocator();
    await getIt<LayoutService>().init();

    // 4. Inicializa o Firebase
    dev.log("--- INICIALIZANDO FIREBASE ---");
    try {
      await Firebase.initializeApp(
        options: FirebaseRemoteConfigs.currentOptions,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Timeout ao inicializar Firebase."),
      );
      print("Firebase Inicializado com Sucesso!");
    } catch (e) {
      print("Erro na inicialização do Firebase: $e");
    }

    // 5. Configurações de Crashlytics e Analytics
    // Captura erros fatais do Flutter
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Captura erros assíncronos não tratados (PlatformDispatcher)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Inicializa Analytics
    FirebaseAnalytics.instance.logAppOpen();

    // 5. Inicializa Notificações
    await getIt<NotificationService>().initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Configurações de Firestore e Storage
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    runApp(const App());
  } catch (e, stack) {
    dev.log("ERRO CRÍTICO NA INICIALIZAÇÃO: $e");
    dev.log("Stack: $stack");
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Erro ao iniciar app: $e"))),
      ),
    );
  }
}
