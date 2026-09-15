import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_tenda/core/config/app_config.dart'; // Ajustado para o novo caminho

class FirebaseRemoteConfigs {
  // Credenciais Globais do projeto Firebase
  static const String _apiKey = "AIzaSyAB13hEUwX_evF2FvUHOGQ49d0IlQrtBrU";
  static const String _projectId = "tenda-white-label";
  static const String _senderId = "201327273520";

  static FirebaseOptions get currentOptions {
    final tenant = AppConfig.instance.tenant;
    final env = AppConfig.instance.environment;

    // MAPA AUTOMÁTICO DE APP IDs
    final Map<String, Map<AppEnvironment, String>> appIds;

    // Novos tenants: adicione uma nova entrada no mapa (iOS e Android) com o
    // App ID gerado no console do Firebase para o projeto tenda-white-label.
    if (Platform.isIOS) {
      appIds = {
        'tucttx': {
          AppEnvironment.dev: '1:201327273520:ios:9f4f613b5ab70956a56ff5',
          AppEnvironment.prod: '1:201327273520:ios:a379a2131bb5a361a56ff5',
        },
      };
    } else {
      // ANDROID
      appIds = {
        'tucttx': {
          // ID do firebase.json (Default)
          AppEnvironment.dev: '1:201327273520:android:b02e66280b62f3f2a56ff5',
          AppEnvironment.prod: '1:201327273520:android:2de1a0b8c594a509a56ff5',
        },
      };
    }

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
