import 'package:app_tenda/features/finance/domain/models/financial_models.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';

/// Regras de envio de comprovante, isoladas para serem testáveis sem Firebase.
class ReceiptSubmissionValidator {
  static const double _tolerance = 0.005;

  /// Converte "1.234,56" ou "1234.56" em número; null se inválido.
  static double? parseMoney(String input) {
    var text = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (text.isEmpty) return null;
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(text);
  }

  /// Retorna a mensagem de erro, ou null quando o envio é válido.
  ///
  /// [fees] são as mensalidades do membro; [openRequests] as solicitações que
  /// ainda aguardam aprovação (para bloquear envio duplicado do mesmo mês).
  static String? validate({
    required List<PaymentRequestItem> items,
    required double? totalValue,
    required DateTime? paidDate,
    required bool hasFile,
    required List<MonthlyFeeModel> fees,
    required List<PaymentRequestModel> openRequests,
    DateTime? now,
  }) {
    if (items.isEmpty) return 'Selecione ao menos um mês.';

    if (items.any((i) => i.value <= 0)) {
      return 'Informe um valor maior que zero para cada mês selecionado.';
    }

    if (totalValue == null || totalValue <= 0) {
      return 'Informe o valor total do comprovante.';
    }

    final sum = items.fold<double>(0, (acc, i) => acc + i.value);
    if ((sum - totalValue).abs() > _tolerance) {
      return 'A soma dos meses (R\$ ${sum.toStringAsFixed(2)}) não bate com o '
          'total do comprovante (R\$ ${totalValue.toStringAsFixed(2)}).';
    }

    if (paidDate == null) return 'Informe a data do pagamento.';
    final today = now ?? DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final paidOnly = DateTime(paidDate.year, paidDate.month, paidDate.day);
    if (paidOnly.isAfter(todayOnly)) {
      return 'A data do pagamento não pode ser futura.';
    }

    if (!hasFile) return 'Anexe o comprovante (imagem ou PDF).';

    for (final item in items) {
      final paid = fees.any(
        (f) =>
            f.month == item.month &&
            f.year == item.year &&
            f.status == FinanceStatus.paid,
      );
      if (paid) return 'O mês ${item.month}/${item.year} já está pago.';

      final open = openRequests.any(
        (r) => r.items.any(
          (i) =>
              i.month == item.month &&
              i.year == item.year &&
              i.status == PaymentItemStatus.pendingApproval,
        ),
      );
      if (open) {
        return 'O mês ${item.month}/${item.year} já tem um comprovante '
            'aguardando aprovação.';
      }
    }

    return null;
  }

  /// Content-type aceito pelo Storage (storage.rules); null se não suportado.
  static String? contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }
}
