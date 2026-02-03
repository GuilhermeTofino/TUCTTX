import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_models.dart';
import '../../data/datasources/base_firestore_datasource.dart';

abstract class FinanceRepository {
  Stream<List<MonthlyFeeModel>> getUserMonthlyFees(
    String tenantId,
    String userId,
  );
  Stream<List<BazaarDebtModel>> getUserBazaarDebts(
    String tenantId,
    String userId,
  );

  // Admin methods
  Future<void> updateMonthlyFeeStatus(
    String userId,
    String feeId,
    FinanceStatus status, {
    double? value,
  });
  Future<void> addBazaarDebt(BazaarDebtModel debt);
  Future<void> markBazaarDebtAsPaid(String userId, String debtId);
  Future<void> syncMonthlyFeesForYear(
    String userId,
    int year,
    double defaultValue,
  );
}

class FirebaseFinanceRepository extends BaseFirestoreDataSource
    implements FinanceRepository {
  @override
  Stream<List<MonthlyFeeModel>> getUserMonthlyFees(
    String tenantId,
    String userId,
  ) {
    return tenantCollection('financial')
        .doc(userId)
        .collection('monthly_fees')
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MonthlyFeeModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  @override
  Stream<List<BazaarDebtModel>> getUserBazaarDebts(
    String tenantId,
    String userId,
  ) {
    return tenantCollection('financial')
        .doc(userId)
        .collection('bazaar_debts')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BazaarDebtModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  @override
  Future<void> updateMonthlyFeeStatus(
    String userId,
    String feeId,
    FinanceStatus status, {
    double? value,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == FinanceStatus.paid) {
      data['paidAt'] = FieldValue.serverTimestamp();
    } else {
      data['paidAt'] = null;
    }
    if (value != null) {
      data['value'] = value;
    }

    await tenantCollection(
      'financial',
    ).doc(userId).collection('monthly_fees').doc(feeId).update(data);
  }

  @override
  Future<void> addBazaarDebt(BazaarDebtModel debt) async {
    await tenantCollection(
      'financial',
    ).doc(debt.userId).collection('bazaar_debts').add(debt.toMap());
  }

  @override
  Future<void> markBazaarDebtAsPaid(String userId, String debtId) async {
    await tenantCollection('financial')
        .doc(userId)
        .collection('bazaar_debts')
        .doc(debtId)
        .update({'isPaid': true, 'paidAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> syncMonthlyFeesForYear(
    String userId,
    int year,
    double defaultValue,
  ) async {
    final coll = tenantCollection(
      'financial',
    ).doc(userId).collection('monthly_fees');

    for (int m = 1; m <= 12; m++) {
      final docId = '${year}_$m';
      final doc = await coll.doc(docId).get();

      if (!doc.exists) {
        await coll.doc(docId).set({
          'userId': userId,
          'month': m,
          'year': year,
          'value': defaultValue,
          'status': FinanceStatus.pending.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
