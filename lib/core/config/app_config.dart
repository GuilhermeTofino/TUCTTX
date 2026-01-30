import 'package:flutter/material.dart';

enum AppEnvironment { dev, prod }

class TenantConfig {
  final String tenantName;
  final String tenantSlug;
  final String appTitle;
  final Color primaryColor;
  final String bundleId;
  final String responsavel;

  const TenantConfig({
    required this.tenantName,
    required this.tenantSlug,
    required this.appTitle,
    required this.primaryColor,
    required this.bundleId,
    required this.responsavel,
  });

  // Getter para garantir que o texto sobre a cor primária seja sempre visível
  // Se a cor for clara, retorna preto; se for escura, retorna branco.
  Color get onPrimaryColor => 
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  // Atalho para o caminho da logo
  String get logoPath => 'assets/tenants/$tenantSlug/logo.png';
}

class AppConfig {
  final AppEnvironment environment;
  final TenantConfig tenant;

  static AppConfig? _instance;
  AppConfig._({required this.environment, required this.tenant});

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception("AppConfig deve ser instanciado antes do uso. Verifique o main.dart");
    }
    return _instance!;
  }

  static void instantiate({
    required AppEnvironment environment,
    required TenantConfig tenant,
  }) {
    _instance = AppConfig._(environment: environment, tenant: tenant);
  }
}