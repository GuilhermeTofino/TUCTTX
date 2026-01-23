import 'package:app_tenda/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'core/config/tenant_factory.dart';
import 'core/di/service_locator.dart';
import 'firebase_options.dart';

void main() async {
  // Garante que os bindings nativos estejam prontos
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Captura variáveis de ambiente
  const String tenantSlug = String.fromEnvironment('TENANT');
  const String envRaw = String.fromEnvironment('ENV');
  final environment = envRaw == 'prod'
      ? AppEnvironment.prod
      : AppEnvironment.dev;

  // 2. Inicializa a configuração global do Tenant
  AppConfig.instantiate(
    environment: environment,
    tenant: TenantFactory.getTenant(tenantSlug, environment),
  );

  // 3. Inicializa o Service Locator (Injeção de Dependência)
  await setupServiceLocator();

  // 4. Inicializa o Firebase com as opções geradas pelo CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      home: const HomePage(),
    );
  }
}
