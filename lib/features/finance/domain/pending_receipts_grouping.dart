import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';

/// Um mês ainda aguardando decisão, com a solicitação (comprovante) de origem.
class PendingMonth {
  final PaymentRequestModel request;
  final PaymentRequestItem item;
  const PendingMonth(this.request, this.item);
}

/// Meses pendentes de um mesmo membro.
class UserPendingGroup {
  final String userId;
  final String userName;
  final List<PendingMonth> months;
  const UserPendingGroup({
    required this.userId,
    required this.userName,
    required this.months,
  });

  /// Envio mais antigo do grupo, para priorizar quem espera há mais tempo.
  DateTime get oldest => months
      .map((m) => m.request.createdAt ?? m.request.paidDate)
      .reduce((a, b) => a.isBefore(b) ? a : b);
}

/// Agrupa por membro apenas os meses pendentes, sem as solicitações de
/// [excludeUserId] (quem aprova não decide o próprio comprovante).
/// Grupos do mais antigo ao mais novo; meses em ordem cronológica.
List<UserPendingGroup> groupPendingByUser(
  List<PaymentRequestModel> requests, {
  String? excludeUserId,
}) {
  final byUser = <String, List<PendingMonth>>{};
  final names = <String, String>{};

  for (final request in requests) {
    if (request.userId == excludeUserId) continue;
    for (final item in request.items) {
      if (item.status != PaymentItemStatus.pendingApproval) continue;
      byUser.putIfAbsent(request.userId, () => []).add(PendingMonth(request, item));
      names[request.userId] = request.userName;
    }
  }

  final groups = byUser.entries.map((entry) {
    final months = entry.value
      ..sort((a, b) {
        final byYear = a.item.year.compareTo(b.item.year);
        return byYear != 0 ? byYear : a.item.month.compareTo(b.item.month);
      });
    return UserPendingGroup(
      userId: entry.key,
      userName: names[entry.key] ?? '',
      months: months,
    );
  }).toList();

  groups.sort((a, b) => a.oldest.compareTo(b.oldest));
  return groups;
}
