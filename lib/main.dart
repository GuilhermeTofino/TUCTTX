import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/config/tenant_factory.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Injetados via --dart-define no build
  const String tenantSlug = String.fromEnvironment('TENANT');
  const String envRaw = String.fromEnvironment('ENV');

  final environment = envRaw == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;
  
  AppConfig.instantiate(
    environment: environment,
    tenant: TenantFactory.getTenant(tenantSlug, environment),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    
    return MaterialApp(
      title: config.tenant.appTitle,
      home: Scaffold(
        appBar: AppBar(title: Text(config.tenant.appTitle)),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID do Cliente (Firebase): ${config.tenant.tenantSlug}', 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Text('Ambiente: ${config.environment.name}'),
              const Divider(),
              const Text('Exemplo de path Firestore:'),
              Text('tenants/${config.tenant.tenantSlug}/users/123'),
              const SizedBox(height: 10),
              const Text('Exemplo de Tópico FCM:'),
              Text('topic_${config.tenant.tenantSlug}_${config.environment.name}'),
            ],
          ),
        ),
      ),
    );
  }
}