/// Validação do "Editar Meu Cadastro", isolada para ser testável.
class ProfileValidation {
  /// Mensagem de erro, ou null se o nome é aceitável.
  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Informe seu nome.';
    if (v.length < 2) return 'O nome está muito curto.';
    return null;
  }

  /// Telefone brasileiro com DDD: 10 ou 11 dígitos (aceita máscara).
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe seu telefone.';
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone inválido. Use DDD + número.';
    }
    return null;
  }

  /// Data de nascimento opcional; se informada, não pode ser futura nem absurda.
  static String? birthDate(DateTime? value, {DateTime? now}) {
    if (value == null) return null;
    final today = now ?? DateTime.now();
    if (value.isAfter(today)) return 'A data de nascimento não pode ser futura.';
    if (value.year < 1900) return 'Data de nascimento inválida.';
    return null;
  }

  /// Texto opcional: vazio vira null (não grava campo em branco).
  static String? optional(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? null : v;
  }
}
