import 'package:flutter/material.dart';
import 'package:app_tenda/core/config/app_config.dart';

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
          bundleId: 'com.appTenda.tucttx$suffix',
          responsavel: 'Pai Ricardo',
          pixKey: 'tucttx@gmail.com',
          paymentLink: 'https://mpago.la/tucttx',
        );
      // Novos tenants: adicione um novo `case` aqui seguindo o modelo acima.
      default:
        throw Exception('Tenant "$slug" não encontrado na Factory.');
    }
  }
}
