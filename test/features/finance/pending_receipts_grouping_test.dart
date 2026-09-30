import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/pending_receipts_grouping.dart';

PaymentRequestItem item(
  int month, {
  int year = 2026,
  PaymentItemStatus status = PaymentItemStatus.pendingApproval,
}) => PaymentRequestItem(month: month, year: year, value: 100, status: status);

PaymentRequestModel request(
  String id,
  String userId,
  List<PaymentRequestItem> items, {
  DateTime? createdAt,
}) => PaymentRequestModel(
  id: id,
  userId: userId,
  userName: 'Nome $userId',
  items: items,
  totalValue: 100.0 * items.length,
  paidDate: DateTime(2026, 9, 1),
  receiptPath: 'p/$id',
  createdAt: createdAt,
);

void main() {
  test('agrupa meses pendentes por membro, em ordem cronológica', () {
    final groups = groupPendingByUser([
      request('r1', 'a', [item(10), item(8)], createdAt: DateTime(2026, 9, 5)),
      request('r2', 'a', [item(9)], createdAt: DateTime(2026, 9, 6)),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.months.map((m) => m.item.month), [8, 9, 10]);
    expect(groups.single.userName, 'Nome a');
  });

  test('ignora meses já decididos e solicitações sem pendência', () {
    final groups = groupPendingByUser([
      request('r1', 'a', [
        item(8, status: PaymentItemStatus.approved),
        item(9),
      ]),
      request('r2', 'b', [item(8, status: PaymentItemStatus.rejected)]),
    ]);

    expect(groups.map((g) => g.userId), ['a']);
    expect(groups.single.months.map((m) => m.item.month), [9]);
  });

  test('não lista o comprovante do próprio aprovador', () {
    final groups = groupPendingByUser([
      request('r1', 'eu', [item(9)]),
      request('r2', 'outro', [item(9)]),
    ], excludeUserId: 'eu');

    expect(groups.map((g) => g.userId), ['outro']);
  });

  test('quem espera há mais tempo aparece primeiro', () {
    final groups = groupPendingByUser([
      request('r1', 'novo', [item(9)], createdAt: DateTime(2026, 9, 20)),
      request('r2', 'antigo', [item(8)], createdAt: DateTime(2026, 9, 2)),
    ]);

    expect(groups.map((g) => g.userId), ['antigo', 'novo']);
  });

  test('meses de anos diferentes ordenam por ano antes do mês', () {
    final groups = groupPendingByUser([
      request('r1', 'a', [item(1, year: 2027), item(12, year: 2026)]),
    ]);

    expect(
      groups.single.months.map((m) => '${m.item.year}-${m.item.month}'),
      ['2026-12', '2027-1'],
    );
  });

  test('sem pendências devolve lista vazia', () {
    expect(groupPendingByUser([]), isEmpty);
  });
}
