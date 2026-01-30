import 'package:firebase_core/firebase_core.dart';
import '../config/app_config.dart'; // Ajustado para o novo caminho

class FirebaseRemoteConfigs {
  // Credenciais Globais do projeto Firebase
  static const String _apiKey = "AIzaSyAB13hEUwX_evF2FvUHOGQ49d0IlQrtBrU";
  static const String _projectId = "tenda-white-label";
  static const String _senderId = "201327273520";

  static FirebaseOptions get currentOptions {
    final tenant = AppConfig.instance.tenant;
    final env = AppConfig.instance.environment;

    // MAPA AUTOMÁTICO DE APP IDs
    final Map<String, Map<AppEnvironment, String>> appIds = {
      'tucttx': {
        AppEnvironment.dev: '1:201327273520:ios:d0115f9ebc723ab3a56ff5',
        AppEnvironment.prod: '1:201327273520:ios:a379a2131bb5a361a56ff5',
      },
      'tu7e': {
        AppEnvironment.dev: '1:201327273520:ios:0f65388973997387a56ff5',
        AppEnvironment.prod: '1:201327273520:ios:47f76c7f7f04be47a56ff5',
      },
      'tusva': {
        AppEnvironment.dev: '1:201327273520:ios:48062891fd4e25a2a56ff5',
        AppEnvironment.prod: '1:201327273520:ios:5ceb177c6e398c1fa56ff5',
      },
    };

    // Validação de segurança: verifica se o tenant e o ambiente existem no mapa
    final tenantAppIds = appIds[tenant.tenantSlug];
    if (tenantAppIds == null || tenantAppIds[env] == null) {
      throw Exception(
        "Configuração do Firebase não encontrada para o cliente: ${tenant.tenantSlug} no ambiente: $env",
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: tenantAppIds[env]!,
      messagingSenderId: _senderId,
      projectId: _projectId,
      storageBucket: "tenda-white-label.firebasestorage.app",
      iosBundleId: tenant.bundleId,
    );
  }
}
