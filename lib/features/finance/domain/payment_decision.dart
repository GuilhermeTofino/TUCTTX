import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';

/// Aplica a decisão do aprovador a um mês da solicitação, sem tocar em
/// Firestore (a transação fica no repositório).
///
/// Lança [StateError] com 'item-not-found' ou 'item-already-decided', e
/// [ArgumentError] para valor corrigido inválido ou rejeição sem motivo.
List<PaymentRequestItem> applyDecision(
  List<PaymentRequestItem> items, {
  required int month,
  required int year,
  required bool approve,
  required String approverId,
  required DateTime now,
  double? correctedValue,
  String? rejectReason,
}) {
  final index = items.indexWhere((i) => i.month == month && i.year == year);
  if (index == -1) throw StateError('item-not-found');

  final item = items[index];
  if (item.status != PaymentItemStatus.pendingApproval) {
    throw StateError('item-already-decided');
  }

  late final PaymentRequestItem decided;
  if (approve) {
    final value = correctedValue ?? item.value;
    if (value <= 0) throw ArgumentError('Informe um valor maior que zero.');
    decided = PaymentRequestItem(
      month: item.month,
      year: item.year,
      value: value,
      status: PaymentItemStatus.approved,
      // Guarda o que o membro informou só quando o aprovador corrigiu.
      originalValue: value == item.value ? null : item.value,
      decidedBy: approverId,
      decidedAt: now,
    );
  } else {
    final reason = rejectReason?.trim() ?? '';
    if (reason.isEmpty) throw ArgumentError('Informe o motivo da rejeição.');
    decided = PaymentRequestItem(
      month: item.month,
      year: item.year,
      value: item.value,
      status: PaymentItemStatus.rejected,
      decidedBy: approverId,
      decidedAt: now,
      rejectReason: reason,
    );
  }

  return [...items]..[index] = decided;
}

/// Situação geral: enquanto houver mês pendente a solicitação segue aberta;
/// concluída, é aprovada, rejeitada ou parcial (mistura dos dois).
PaymentRequestStatus overallStatus(List<PaymentRequestItem> items) {
  if (items.any((i) => i.status == PaymentItemStatus.pendingApproval)) {
    return PaymentRequestStatus.pendingApproval;
  }
  if (items.every((i) => i.status == PaymentItemStatus.approved)) {
    return PaymentRequestStatus.approved;
  }
  if (items.every((i) => i.status == PaymentItemStatus.rejected)) {
    return PaymentRequestStatus.rejected;
  }
  return PaymentRequestStatus.partial;
}
