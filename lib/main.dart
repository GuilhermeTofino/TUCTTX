import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as dev;

// Configurações e Core
import 'core/config/app_config.dart';
import 'core/config/tenant_factory.dart';
import 'core/services/firebase_remote_configs.dart';
import 'core/routes/app_routes.dart';
import 'core/di/service_locator.dart';

void main() async {
  try {
    // Garante que os bindings do Flutter estejam prontos
    WidgetsFlutterBinding.ensureInitialized();

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

    // 4. Inicializa o Firebase com tratamento de erro e Log
    dev.log("--- INICIALIZANDO FIREBASE ---");
    dev.log("Tenant: ${tenant.tenantName}");
    dev.log("Project ID: ${FirebaseRemoteConfigs.currentOptions.projectId}");

    await Firebase.initializeApp(
      options: FirebaseRemoteConfigs.currentOptions,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception("Timeout ao inicializar Firebase."),
    );

    dev.log("Firebase inicializado com sucesso!");
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print(
      "Bucket configurado: ${FirebaseStorage.instance.app.options.storageBucket}",
    );
    runApp(const MyApp());
  } catch (e, stack) {
    dev.log("ERRO CRÍTICO NA INICIALIZAÇÃO: $e");
    dev.log("Stack: $stack");
    // Se falhar, roda um App de erro simples para não ficar tela preta
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
    // Pegamos a instância única configurada no main
    final tenant = AppConfig.instance.tenant;

    return MaterialApp(
      title: tenant.appTitle,
      debugShowCheckedModeBanner: false,

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
            // Em vez de Size(double.infinity, 48), use:
            minimumSize: const Size(
              64,
              48,
            ), // O Flutter vai expandir se necessário, mas não força o infinito
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
