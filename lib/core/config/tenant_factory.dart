import 'package:flutter/material.dart';
import 'app_config.dart';

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
      case 'tu7e':
        return TenantConfig(
          tenantName: 'TU7E',
          tenantSlug: 'tu7e',
          appTitle: '$prefix TU7E',
          primaryColor: const Color(0xFF62A24F),
          bundleId: 'com.appTenda.tu7e$suffix',
          responsavel: 'Pai Mauricio',
          pixKey: '77.888.999/0001-22',
          paymentLink: 'https://picpay.me/tu7e',
        );
      case 'tusva':
        return TenantConfig(
          tenantName: 'TUSVA',
          tenantSlug: 'tusva',
          appTitle: '$prefix TUSVA',
          primaryColor: const Color(0xFFFB0101),
          bundleId: 'com.appTenda.tusva$suffix',
          responsavel: 'Mãe Gabi',
          pixKey: '33999887766',
          paymentLink: 'https://pag.ae/tusva',
        );
      default:
        throw Exception('Tenant "$slug" não encontrado na Factory.');
    }
  }
}
