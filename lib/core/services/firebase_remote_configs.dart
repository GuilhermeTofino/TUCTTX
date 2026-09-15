import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_tenda/core/config/app_config.dart'; // Ajustado para o novo caminho

class FirebaseRemoteConfigs {
  // Credenciais Globais do projeto Firebase
  static const String _apiKey = "AIzaSyAB13hEUwX_evF2FvUHOGQ49d0IlQrtBrU";
  static const String _projectId = "tenda-white-label";
  static const String _senderId = "201327273520";

  // TODO(fase 2 - nativo/EloApp): o app agora é único (não existe mais um
  // bundle/App ID por tenant, já que a casa é resolvida em runtime após o
  // login). Estes valores ainda são os do app antigo (com.appTenda.tucttx).
  // Quando o bundle ID único do EloApp for registrado no console do
  // Firebase, troque _iosBundleId e os mapas abaixo pelos novos App IDs.
  static const String _iosBundleId = 'com.appTenda.tucttx';

  static const Map<AppEnvironment, String> _iosAppIds = {
    AppEnvironment.dev: '1:201327273520:ios:9f4f613b5ab70956a56ff5',
    AppEnvironment.prod: '1:201327273520:ios:a379a2131bb5a361a56ff5',
  };

  static const Map<AppEnvironment, String> _androidAppIds = {
    AppEnvironment.dev: '1:201327273520:android:b02e66280b62f3f2a56ff5',
    AppEnvironment.prod: '1:201327273520:android:2de1a0b8c594a509a56ff5',
  };

  // Não depende mais do tenant: o Firebase precisa inicializar ANTES do
  // login (é o login que descobre a casa do usuário), então essa config só
  // pode variar por ambiente (dev/prod), nunca por tenant.
  static FirebaseOptions get currentOptions {
    final env = AppConfig.instance.environment;
    final appIds = Platform.isIOS ? _iosAppIds : _androidAppIds;
    final appId = appIds[env];

    if (appId == null) {
      throw Exception(
        "Configuração do Firebase não encontrada para o ambiente: $env",
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      storageBucket: "tenda-white-label.firebasestorage.app",
      iosBundleId: _iosBundleId,
    );
  }
}
