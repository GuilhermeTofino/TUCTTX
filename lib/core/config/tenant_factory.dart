import 'package:app_tenda/core/config/app_config.dart';
import 'package:flutter/material.dart';

class TenantFactory {
  static TenantConfig getTenant(String slug, AppEnvironment env) {
    final isDev = env == AppEnvironment.dev;
    final suffix = isDev ? '.dev' : '';
    final prefix = isDev ? '[DEV] ' : '';

    switch (slug) {
      case 'tucttx':
        return TenantConfig(
          tenantName: 'TUCTTX',
          tenantSlug: 'tucttx',
          appTitle: '$prefix Tenda CT',
          primaryColor: const Color(0xFF72150E),
          bundleId:
              'com.appTenda.tucttx$suffix', // Gera o ID correto conforme ambiente
        );
      // Repita para tu7e e tusva...
      default:
        throw Exception('Tenant inválido');
    }
  }
}
