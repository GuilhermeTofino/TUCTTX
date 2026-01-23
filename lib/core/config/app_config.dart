import 'package:flutter/material.dart';

enum AppEnvironment { dev, prod }


class TenantConfig {
  final String tenantName;
  final String tenantSlug;
  final String appTitle;
  final Color primaryColor; // Nova propriedade

  const TenantConfig({
    required this.tenantName,
    required this.tenantSlug,
    required this.appTitle,
    required this.primaryColor,
  });
}

class AppConfig {
  final AppEnvironment environment;
  final TenantConfig tenant;

  static AppConfig? _instance;
  AppConfig._({required this.environment, required this.tenant});

  static AppConfig get instance => _instance!;

  static void instantiate({
    required AppEnvironment environment,
    required TenantConfig tenant,
  }) {
    _instance = AppConfig._(environment: environment, tenant: tenant);
  }
}