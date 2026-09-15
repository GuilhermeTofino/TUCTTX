import 'package:flutter/material.dart';

enum AppEnvironment { dev, prod }

/// Dados de uma "casa" (instituição religiosa) específica.
///
/// Diferente do modelo antigo, isso NÃO é mais fixado em código por build:
/// é carregado do Firestore (doc `environments/{env}/tenants/{slug}`) depois
/// que o login descobre a qual casa o usuário pertence. Veja
/// [lib/core/config/tenant_repository.dart].
class TenantConfig {
  final String tenantSlug;
  final String tenantName;
  final Color primaryColor;
  final String responsavel;

  /// Código que o dirigente repassa aos filhos/irmãos de fé pra eles
  /// entrarem nessa casa específica no cadastro (em vez de escolher de uma
  /// lista pública). Só deve ser exibido pra admins da própria casa.
  final String? inviteCode;

  /// URL da logo no Storage (em vez de asset local), já que casas novas
  /// podem ser cadastradas sem gerar um novo build do app.
  final String? logoUrl;
  final String? pixKey;
  final String? paymentLink;

  const TenantConfig({
    required this.tenantSlug,
    required this.tenantName,
    required this.primaryColor,
    required this.responsavel,
    this.inviteCode,
    this.logoUrl,
    this.pixKey,
    this.paymentLink,
  });

  // Getter para garantir que o texto sobre a cor primária seja sempre visível
  // Se a cor for clara, retorna preto; se for escura, retorna branco.
  Color get onPrimaryColor =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  factory TenantConfig.fromMap(String slug, Map<String, dynamic> map) {
    final colorHex = map['primaryColor'] as String?;
    return TenantConfig(
      tenantSlug: slug,
      tenantName: map['tenantName'] as String? ?? slug,
      primaryColor: _colorFromHex(colorHex) ?? const Color(0xFF72150E),
      responsavel: map['responsavel'] as String? ?? '',
      inviteCode: map['inviteCode'] as String?,
      logoUrl: map['logoUrl'] as String?,
      pixKey: map['pixKey'] as String?,
      paymentLink: map['paymentLink'] as String?,
    );
  }

  static Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    return value != null ? Color(value) : null;
  }
}

/// Configuração global do app.
///
/// `environment` é conhecido desde o boot (dev/prod). `tenant` só existe
/// depois que o login resolve a casa do usuário — por isso é anulável e
/// exposto via [ChangeNotifier], para que a UI (tema, logo, cor) reaja
/// assim que a casa é carregada, sem precisar reiniciar o app.
class AppConfig extends ChangeNotifier {
  final AppEnvironment environment;
  TenantConfig? _tenant;

  static AppConfig? _instance;
  AppConfig._({required this.environment});

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception(
        "AppConfig deve ser instanciado antes do uso. Verifique o main.dart",
      );
    }
    return _instance!;
  }

  static void instantiate({required AppEnvironment environment}) {
    _instance = AppConfig._(environment: environment);
  }

  bool get hasTenant => _tenant != null;

  /// Lança exceção se acessado antes do login resolver a casa do usuário.
  /// Só deve ser chamado por código que já roda pós-login (telas internas,
  /// repositórios de dados do tenant).
  TenantConfig get tenant {
    final current = _tenant;
    if (current == null) {
      throw Exception(
        "Nenhuma casa religiosa carregada ainda. Isso só fica disponível "
        "depois que o usuário faz login.",
      );
    }
    return current;
  }

  void setTenant(TenantConfig tenant) {
    _tenant = tenant;
    notifyListeners();
  }

  /// Chamar no logout, para o próximo login partir limpo.
  void clearTenant() {
    _tenant = null;
    notifyListeners();
  }
}
