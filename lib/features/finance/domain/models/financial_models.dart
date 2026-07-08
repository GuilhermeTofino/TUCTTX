import 'package:cloud_firestore/cloud_firestore.dart';

enum FinanceStatus { paid, pending, late }

class MonthlyFeeModel {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double value;
  final FinanceStatus status;
  final DateTime? paidAt;
  final DateTime? updatedAt;

  MonthlyFeeModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.value,
    required this.status,
    this.paidAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month,
      'year': year,
      'value': value,
      'status': status.name,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MonthlyFeeModel.fromMap(Map<String, dynamic> map) {
    return MonthlyFeeModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      month: map['month'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      value: (map['value'] ?? 0.0).toDouble(),
      status: FinanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FinanceStatus.pending,
      ),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BazaarDebtModel {
  final String id;
  final String userId;
  final String itemName;
  final double value;
  final DateTime date;
  final bool isPaid;
  final DateTime? paidAt;

  BazaarDebtModel({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.value,
    required this.date,
    this.isPaid = false,
    this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'itemName': itemName,
      'value': value,
      'date': Timestamp.fromDate(date),
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BazaarDebtModel.fromMap(Map<String, dynamic> map) {
    return BazaarDebtModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      itemName: map['itemName'] ?? '',
      value: (map['value'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      isPaid: map['isPaid'] ?? false,
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}
