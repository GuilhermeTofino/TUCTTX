import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/finance/domain/models/financial_models.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/receipt_submission_validator.dart';

MonthlyFeeModel fee(int month, {FinanceStatus status = FinanceStatus.pending}) =>
    MonthlyFeeModel(
      id: '2026_$month',
      userId: 'u1',
      month: month,
      year: 2026,
      value: 100,
      status: status,
    );

PaymentRequestItem item(
  int month,
  double value, {
  PaymentItemStatus status = PaymentItemStatus.pendingApproval,
}) => PaymentRequestItem(month: month, year: 2026, value: value, status: status);

String? validate({
  List<PaymentRequestItem>? items,
  double? total = 100,
  DateTime? paidDate,
  bool hasFile = true,
  List<MonthlyFeeModel>? fees,
  List<PaymentRequestModel> open = const [],
}) {
  return ReceiptSubmissionValidator.validate(
    items: items ?? [item(8, 100)],
    totalValue: total,
    paidDate: paidDate ?? DateTime(2026, 9, 10),
    hasFile: hasFile,
    fees: fees ?? [fee(8), fee(9)],
    openRequests: open,
    now: DateTime(2026, 9, 29),
  );
}

void main() {
  group('parseMoney', () {
    test('aceita formato brasileiro e ponto decimal', () {
      expect(ReceiptSubmissionValidator.parseMoney('1.234,56'), 1234.56);
      expect(ReceiptSubmissionValidator.parseMoney('R\$ 80,5'), 80.5);
      expect(ReceiptSubmissionValidator.parseMoney('100.50'), 100.5);
    });

    test('devolve null para vazio ou inválido', () {
      expect(ReceiptSubmissionValidator.parseMoney(''), isNull);
      expect(ReceiptSubmissionValidator.parseMoney('abc'), isNull);
    });
  });

  group('validate', () {
    test('envio válido não tem erro', () {
      expect(validate(), isNull);
    });

    test('exige ao menos um mês', () {
      expect(validate(items: []), contains('ao menos um mês'));
    });

    test('recusa valor zero em algum mês', () {
      expect(validate(items: [item(8, 0)]), contains('maior que zero'));
    });

    test('soma dos meses precisa bater com o total', () {
      final error = validate(items: [item(8, 60), item(9, 30)], total: 100);
      expect(error, contains('não bate'));
      expect(
        validate(items: [item(8, 60), item(9, 40)], total: 100),
        isNull,
      );
    });

    test('tolera diferença de centavos por arredondamento', () {
      expect(validate(items: [item(8, 33.333), item(9, 66.667)]), isNull);
    });

    test('data futura é recusada, hoje é aceito', () {
      expect(validate(paidDate: DateTime(2026, 9, 30)), contains('futura'));
      expect(validate(paidDate: DateTime(2026, 9, 29, 23, 59)), isNull);
    });

    test('exige data e arquivo', () {
      expect(validate(hasFile: false), contains('Anexe'));
    });

    test('recusa mês já pago', () {
      final error = validate(
        fees: [fee(8, status: FinanceStatus.paid), fee(9)],
      );
      expect(error, contains('já está pago'));
    });

    test('recusa mês com comprovante em análise', () {
      final open = PaymentRequestModel(
        id: 'r1',
        userId: 'u1',
        userName: 'Fulano',
        items: [item(8, 100)],
        totalValue: 100,
        paidDate: DateTime(2026, 9, 1),
        receiptPath: 'x',
      );
      expect(validate(open: [open]), contains('aguardando aprovação'));
    });

    test('mês rejeitado antes pode ser reenviado', () {
      final rejected = PaymentRequestModel(
        id: 'r1',
        userId: 'u1',
        userName: 'Fulano',
        items: [item(8, 100, status: PaymentItemStatus.rejected)],
        totalValue: 100,
        paidDate: DateTime(2026, 9, 1),
        receiptPath: 'x',
        status: PaymentRequestStatus.rejected,
      );
      expect(validate(open: [rejected]), isNull);
    });
  });

  group('contentTypeFor', () {
    test('mapeia extensões aceitas e recusa as demais', () {
      expect(ReceiptSubmissionValidator.contentTypeFor('a.JPG'), 'image/jpeg');
      expect(ReceiptSubmissionValidator.contentTypeFor('a.png'), 'image/png');
      expect(
        ReceiptSubmissionValidator.contentTypeFor('a.pdf'),
        'application/pdf',
      );
      expect(ReceiptSubmissionValidator.contentTypeFor('a.exe'), isNull);
    });
  });

  group('PaymentRequestModel', () {
    test('ano do arquivo é o do mês mais recente', () {
      final items = [
        const PaymentRequestItem(month: 12, year: 2026, value: 50),
        const PaymentRequestItem(month: 1, year: 2027, value: 50),
      ];
      expect(PaymentRequestModel.receiptYearFor(items), 2027);
    });

    test('feeId segue o id de monthly_fees', () {
      expect(item(9, 10).feeId, '2026_9');
    });
  });
}
