import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/config/emulator_setup.dart';

/// Interruptores ligados pelo Remote Config, sem publicar nova versão.
/// Chaves com prefixo do tenant, como as de atualização forçada.
class FeatureFlags {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String get _visitorSignupKey =>
      '${AppConfig.instance.tenant.tenantSlug}_visitor_signup_enabled';

  /// Cadastros novos entram como consulente? Desligado por padrão: sem parâmetro,
  /// sem internet ou com qualquer falha, devolve false (comportamento de sempre).
  ///
  /// Não mexe em defaults nem no intervalo de busca: o VersionCheckService usa o
  /// mesmo Remote Config e ajustar isso aqui poderia alterar a atualização forçada.
  Future<bool> visitorSignupEnabled() async {
    if (EmulatorSetup.enabled) return true; // no emulador o fluxo é para testar
    try {
      await _remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sem rede/limitado: usa o último valor ativado, ou false se nunca houve.
    }
    return _remoteConfig.getBool(_visitorSignupKey);
  }
}
