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
          appTitle: '$prefix TUCTTX',
          primaryColor: const Color(0xFF72150E),
          bundleId:
              'com.appTenda.$suffix', // Gera o ID correto conforme ambiente
        );
      case 'tu7e':
        return TenantConfig(
          tenantName: 'TU7E',
          tenantSlug: 'tu7e',
          appTitle: '$prefix TU7E',
          primaryColor: const Color(0xFF62A24F),
          bundleId: 'com.appTenda.tu7e$suffix',
        );
      case 'tusva':
        return TenantConfig(
          tenantName: 'TUSVA',
          tenantSlug: 'tusva',
          appTitle: '$prefix TUSVA',
          primaryColor: const Color(0xFFFB0101),
          bundleId: 'com.appTenda.tusva$suffix',
        );

      // Repita para tu7e e tusva...
      default:
        throw Exception('Tenant inválido');
    }
  }
}
