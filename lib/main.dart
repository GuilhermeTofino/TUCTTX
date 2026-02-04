import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as dev;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/config/tenant_factory.dart';
import 'package:app_tenda/core/services/firebase_remote_configs.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_tenda/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

    // 1. Captura variáveis de ambiente
    const slug = String.fromEnvironment('TENANT');
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');

    if (slug.isEmpty) {
      throw Exception(
        "ERRO: O parâmetro TENANT deve ser passado via --dart-define=TENANT=slug",
      );
    }

    // 2. Instancia a configuração global
    final env = envString == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;
    final tenant = TenantFactory.getTenant(slug, env);
    AppConfig.instantiate(environment: env, tenant: tenant);

    // 3. Inicializa Service Locator (Injeção de Dependências)
    await setupServiceLocator();

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

    // 5. Inicializa Notificações
    await getIt<NotificationService>().initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Configurações de Firestore e Storage
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    runApp(const MyApp());
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return MaterialApp(
      title: tenant.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: tenant.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: tenant.primaryColor,
          primary: tenant.primaryColor,
          onPrimary: tenant.onPrimaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: tenant.primaryColor,
          foregroundColor: tenant.onPrimaryColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tenant.primaryColor,
            foregroundColor: tenant.onPrimaryColor,
            minimumSize: const Size(64, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
