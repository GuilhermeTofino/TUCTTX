import 'package:flutter/material.dart';

import 'app_config.dart';

class TenantFactory {
  static TenantConfig getTenant(String tenantSlug, AppEnvironment env) {
    // O prefixo [DEV] ajuda a equipe de QA a identificar o ambiente visualmente
    final String prefix = env == AppEnvironment.dev ? '[DEV] ' : '';

    switch (tenantSlug) {
      // No seu switch dentro de getTenant:
      case 'tucttx':
        return TenantConfig(
          tenantName: 'TUCTTX',
          tenantSlug: 'tucttx',
          appTitle: '${prefix}TUCTTX',
          primaryColor: const Color(0xFF72150E),
        );
      case 'tu7e':
        return TenantConfig(
          tenantName: 'TU7E',
          tenantSlug: 'tu7e',
          appTitle: '${prefix}TU7E',
          primaryColor: const Color(0xFF43A047), // Verde
        );
      case 'tusva':
        return TenantConfig(
          tenantName: 'TUSVA',
          tenantSlug: 'tusva',
          appTitle: '${prefix}TUSVA',
          primaryColor: const Color(0xFFE53935), // Vermelho
        );
      default:
        throw Exception('Tenant não reconhecido: $tenantSlug');
    }
  }
}
