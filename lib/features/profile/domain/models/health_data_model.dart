/// Dados de saúde do membro. Ficam em `users/{uid}/private/health`, e não no
/// documento do usuário, que qualquer membro logado consegue ler (LGPD:
/// dado pessoal sensível). Só o dono grava; dono e admins leem.
class HealthData {
  final String? alergias;
  final String? medicamentos;
  final String? condicoesMedicas;
  final String? tipoSanguineo;

  const HealthData({
    this.alergias,
    this.medicamentos,
    this.condicoesMedicas,
    this.tipoSanguineo,
  });

  bool get isEmpty =>
      _blank(alergias) &&
      _blank(medicamentos) &&
      _blank(condicoesMedicas) &&
      _blank(tipoSanguineo);

  static bool _blank(String? v) => v == null || v.trim().isEmpty;

  /// Texto vazio vira null, para não gravar campos em branco.
  static String? _clean(String? v) => _blank(v) ? null : v!.trim();

  HealthData cleaned() => HealthData(
    alergias: _clean(alergias),
    medicamentos: _clean(medicamentos),
    condicoesMedicas: _clean(condicoesMedicas),
    tipoSanguineo: _clean(tipoSanguineo),
  );

  Map<String, dynamic> toMap() {
    final c = cleaned();
    return {
      'alergias': c.alergias,
      'medicamentos': c.medicamentos,
      'condicoesMedicas': c.condicoesMedicas,
      'tipoSanguineo': c.tipoSanguineo,
    };
  }

  factory HealthData.fromMap(Map<String, dynamic> map) => HealthData(
    alergias: map['alergias'],
    medicamentos: map['medicamentos'],
    condicoesMedicas: map['condicoesMedicas'],
    tipoSanguineo: map['tipoSanguineo'],
  );
}
