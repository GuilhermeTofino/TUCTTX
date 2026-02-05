import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../config/app_config.dart';

class VersionCheckService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1), // Cache de 1 hora
        ),
      );

      // Valores padrão caso não consiga buscar
      // Definimos valores padrão com prefixo baseado no tenant atual para segurança
      final tenantSlug = AppConfig.instance.tenant.tenantSlug;
      await _remoteConfig.setDefaults({
        '${tenantSlug}_min_required_version_ios': '1.0.0',
        '${tenantSlug}_min_required_version_android': '1.0.0',
        '${tenantSlug}_force_update_store_url_ios': '',
        '${tenantSlug}_force_update_store_url_android': '',
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print("Erro ao inicializar Remote Config: $e");
    }
  }

  Future<bool> isUpdateRequired() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final tenantSlug = AppConfig.instance.tenant.tenantSlug;

      String minVersionKey = Platform.isIOS
          ? '${tenantSlug}_min_required_version_ios'
          : '${tenantSlug}_min_required_version_android';

      String minVersion = _remoteConfig.getString(minVersionKey);

      // Se não tiver config, assume que não precisa atualizar
      if (minVersion.isEmpty) return false;

      return _isCurrentVersionLower(currentVersion, minVersion);
    } catch (e) {
      print("Erro ao verificar versão: $e");
      return false; // Em caso de erro, não bloqueia o usuário
    }
  }

  String getStoreUrl() {
    final tenantSlug = AppConfig.instance.tenant.tenantSlug;
    if (Platform.isIOS) {
      return _remoteConfig.getString(
        '${tenantSlug}_force_update_store_url_ios',
      );
    } else {
      return _remoteConfig.getString(
        '${tenantSlug}_force_update_store_url_android',
      );
    }
  }

  bool _isCurrentVersionLower(String current, String min) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> minParts = min.split('.').map(int.parse).toList();

    // Normaliza tamanhos (ex: 1.0 vs 1.0.2 -> 1.0.0 vs 1.0.2)
    while (currentParts.length < 3) currentParts.add(0);
    while (minParts.length < 3) minParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < minParts[i]) {
        return true;
      } else if (currentParts[i] > minParts[i]) {
        return false;
      }
    }
    return false; // Versões iguais
  }
}
