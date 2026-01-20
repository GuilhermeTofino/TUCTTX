enum AppEnvironment { dev, prod }

class TenantConfig {
  final String tenantName;    // Nome amigável (Ex: "TUCTTX")
  final String tenantSlug;    // O ID para o Firebase (Ex: "tucttx")
  final String appTitle;

  const TenantConfig({
    required this.tenantName,
    required this.tenantSlug,
    required this.appTitle,
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