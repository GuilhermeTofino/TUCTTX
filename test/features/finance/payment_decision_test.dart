import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/finance/domain/models/financial_models.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/payment_decision.dart';

PaymentRequestItem item(
  int month, {
  double value = 100,
  PaymentItemStatus status = PaymentItemStatus.pendingApproval,
}) => PaymentRequestItem(month: month, year: 2026, value: value, status: status);

final now = DateTime(2026, 9, 29, 10);

List<PaymentRequestItem> approve(
  List<PaymentRequestItem> items,
  int month, {
  double? corrected,
}) => applyDecision(
  items,
  month: month,
  year: 2026,
  approve: true,
  approverId: 'fin',
  now: now,
  correctedValue: corrected,
);

List<PaymentRequestItem> reject(
  List<PaymentRequestItem> items,
  int month,
  String? reason,
) => applyDecision(
  items,
  month: month,
  year: 2026,
  approve: false,
  approverId: 'fin',
  now: now,
  rejectReason: reason,
);

void main() {
  group('applyDecision', () {
    test('aprova só o mês escolhido e registra quem e quando', () {
      final result = approve([item(8), item(9)], 8);

      expect(result[0].status, PaymentItemStatus.approved);
      expect(result[0].decidedBy, 'fin');
      expect(result[0].decidedAt, now);
      expect(result[0].originalValue, isNull);
      expect(result[1].status, PaymentItemStatus.pendingApproval);
    });

    test('valor corrigido preserva o valor informado pelo membro', () {
      final result = approve([item(8, value: 100)], 8, corrected: 80);

      expect(result.single.value, 80);
      expect(result.single.originalValue, 100);
    });

    test('valor "corrigido" igual ao informado não gera histórico', () {
      final result = approve([item(8, value: 100)], 8, corrected: 100);
      expect(result.single.originalValue, isNull);
    });

    test('valor corrigido precisa ser maior que zero', () {
      expect(() => approve([item(8)], 8, corrected: 0), throwsArgumentError);
      expect(() => approve([item(8)], 8, corrected: -5), throwsArgumentError);
    });

    test('rejeição exige motivo e guarda o texto sem espaços sobrando', () {
      expect(() => reject([item(8)], 8, null), throwsArgumentError);
      expect(() => reject([item(8)], 8, '   '), throwsArgumentError);

      final result = reject([item(8)], 8, '  Valor não caiu no extrato  ');
      expect(result.single.status, PaymentItemStatus.rejected);
      expect(result.single.rejectReason, 'Valor não caiu no extrato');
    });

    test('mês já decidido não pode ser decidido de novo', () {
      final decided = [item(8, status: PaymentItemStatus.approved)];

      expect(
        () => approve(decided, 8),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'item-already-decided',
          ),
        ),
      );
    });

    test('mês que não está na solicitação é recusado', () {
      expect(
        () => approve([item(8)], 12),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'item-not-found'),
        ),
      );
    });

    test('não altera a lista original', () {
      final original = [item(8)];
      approve(original, 8);
      expect(original.single.status, PaymentItemStatus.pendingApproval);
    });
  });

  group('overallStatus', () {
    test('segue aberta enquanto houver mês pendente', () {
      expect(
        overallStatus([item(8, status: PaymentItemStatus.approved), item(9)]),
        PaymentRequestStatus.pendingApproval,
      );
    });

    test('todos aprovados, todos rejeitados ou mistura', () {
      const a = PaymentItemStatus.approved;
      const r = PaymentItemStatus.rejected;
      expect(
        overallStatus([item(8, status: a), item(9, status: a)]),
        PaymentRequestStatus.approved,
      );
      expect(
        overallStatus([item(8, status: r), item(9, status: r)]),
        PaymentRequestStatus.rejected,
      );
      expect(
        overallStatus([item(8, status: a), item(9, status: r)]),
        PaymentRequestStatus.partial,
      );
    });
  });

  group('MonthlyFeeModel.receivedDate', () {
    MonthlyFeeModel fee({DateTime? paidAt}) => MonthlyFeeModel(
      id: '2026_8',
      userId: 'u',
      month: 8,
      year: 2026,
      value: 100,
      status: FinanceStatus.paid,
      paidAt: paidAt,
    );

    test('usa a data do pagamento, não o mês de competência', () {
      expect(fee(paidAt: DateTime(2026, 10, 3)).receivedDate, DateTime(2026, 10, 3));
    });

    test('sem paidAt cai no mês de competência', () {
      expect(fee().receivedDate, DateTime(2026, 8));
    });
  });
}
