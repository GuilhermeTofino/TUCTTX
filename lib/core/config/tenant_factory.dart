import 'app_config.dart';

class TenantFactory {
  static TenantConfig getTenant(String tenantSlug, AppEnvironment env) {
    // O prefixo [DEV] ajuda a equipe de QA a identificar o ambiente visualmente
    final String prefix = env == AppEnvironment.dev ? '[DEV] ' : '';

    switch (tenantSlug) {
      case 'tucttx':
        return TenantConfig(
          tenantName: 'TUCTTX',
          tenantSlug: 'tucttx',
          appTitle: '${prefix}TUCTTX',
        );
      case 'tu7e':
        return TenantConfig(
          tenantName: 'TU7E',
          tenantSlug: 'tu7e',
          appTitle: '${prefix}TU7E',
        );
      case 'tusva':
        return TenantConfig(
          tenantName: 'TUSVA',
          tenantSlug: 'tusva',
          appTitle: '${prefix}TUSVA',
        );
      default:
        throw Exception('Tenant não reconhecido: $tenantSlug');
    }
  }
}