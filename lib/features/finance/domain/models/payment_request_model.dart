import 'package:cloud_firestore/cloud_firestore.dart';

/// Situação de um mês dentro de uma solicitação de baixa de mensalidade.
enum PaymentItemStatus {
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected');

  const PaymentItemStatus(this.value);
  final String value;

  static PaymentItemStatus fromValue(String? value) => values.firstWhere(
    (e) => e.value == value,
    orElse: () => PaymentItemStatus.pendingApproval,
  );
}

/// Situação geral da solicitação (comprovante).
enum PaymentRequestStatus {
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected'),
  partial('partial');

  const PaymentRequestStatus(this.value);
  final String value;

  static PaymentRequestStatus fromValue(String? value) => values.firstWhere(
    (e) => e.value == value,
    orElse: () => PaymentRequestStatus.pendingApproval,
  );
}

/// Um mês coberto pelo comprovante, com o valor informado pelo membro.
class PaymentRequestItem {
  final int month;
  final int year;
  final double value;
  final PaymentItemStatus status;

  /// Valor informado pelo membro, preservado se o aprovador corrigir [value].
  final double? originalValue;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? rejectReason;

  const PaymentRequestItem({
    required this.month,
    required this.year,
    required this.value,
    this.status = PaymentItemStatus.pendingApproval,
    this.originalValue,
    this.decidedBy,
    this.decidedAt,
    this.rejectReason,
  });

  /// Mesmo id usado em `financial/{userId}/monthly_fees/{feeId}`.
  String get feeId => '${year}_$month';

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'year': year,
      'value': value,
      'status': status.value,
      'originalValue': originalValue,
      'decidedBy': decidedBy,
      'decidedAt': decidedAt != null ? Timestamp.fromDate(decidedAt!) : null,
      'rejectReason': rejectReason,
    };
  }

  factory PaymentRequestItem.fromMap(Map<String, dynamic> map) {
    return PaymentRequestItem(
      month: map['month'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      value: (map['value'] ?? 0.0).toDouble(),
      status: PaymentItemStatus.fromValue(map['status']),
      originalValue: (map['originalValue'] as num?)?.toDouble(),
      decidedBy: map['decidedBy'],
      decidedAt: (map['decidedAt'] as Timestamp?)?.toDate(),
      rejectReason: map['rejectReason'],
    );
  }
}

/// Comprovante enviado pelo membro para baixa de uma ou mais mensalidades.
class PaymentRequestModel {
  final String id;
  final String userId;
  final String userName;
  final List<PaymentRequestItem> items;

  /// Valor total do comprovante; deve bater com a soma dos itens.
  final double totalValue;

  /// Data em que o membro efetuou o pagamento (base do `paidAt` na aprovação).
  final DateTime paidDate;
  final String? message;

  /// Caminho do arquivo no Storage (nunca URL pública).
  final String receiptPath;
  final PaymentRequestStatus status;
  final DateTime? createdAt;

  const PaymentRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalValue,
    required this.paidDate,
    required this.receiptPath,
    this.message,
    this.status = PaymentRequestStatus.pendingApproval,
    this.createdAt,
  });

  /// Ano do mês mais recente; define a pasta do arquivo e a retenção anual.
  static int receiptYearFor(List<PaymentRequestItem> items) =>
      items.map((i) => i.year).reduce((a, b) => a > b ? a : b);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'items': items.map((i) => i.toMap()).toList(),
      'totalValue': totalValue,
      'paidDate': Timestamp.fromDate(paidDate),
      'message': message,
      'receiptPath': receiptPath,
      'receiptYear': receiptYearFor(items),
      'status': status.value,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PaymentRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => PaymentRequestItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalValue: (map['totalValue'] ?? 0.0).toDouble(),
      paidDate: (map['paidDate'] as Timestamp).toDate(),
      message: map['message'],
      receiptPath: map['receiptPath'] ?? '',
      status: PaymentRequestStatus.fromValue(map['status']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
