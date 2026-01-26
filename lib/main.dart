import 'package:app_tenda/core/config/firebase_remote_configs.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'core/config/tenant_factory.dart';
import 'core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();

  // 1. Detecta o Tenant e Ambiente via Dart Defines (usados nos Schemes do Xcode)
  const slug = String.fromEnvironment('TENANT');
  const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
  final env = envString == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;

  // 2. Configura a Instância
  final tenant = TenantFactory.getTenant(slug, env);
  AppConfig.instantiate(environment: env, tenant: tenant);

  // 3. Inicializa o Firebase SEM ARQUIVOS FÍSICOS
  await Firebase.initializeApp(options: FirebaseRemoteConfigs.currentOptions);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return MaterialApp(
      title: config.tenant.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.tenant.primaryColor,
          primary: config.tenant.primaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: config.tenant.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
