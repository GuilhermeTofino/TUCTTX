import 'package:flutter/material.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/domain/repositories/finance_repository.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';
import 'package:app_tenda/domain/models/user_model.dart';

class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _repository = getIt<FinanceRepository>();
  final PushTriggerService _pushService = getIt<PushTriggerService>();

  List<MonthlyFeeModel> _monthlyFees = [];
  List<MonthlyFeeModel> get monthlyFees => _monthlyFees;

  List<BazaarDebtModel> _bazaarDebts = [];
  List<BazaarDebtModel> get bazaarDebts => _bazaarDebts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void listenToFinancialData(String tenantId, String userId) {
    _isLoading = true;
    notifyListeners();

    _repository.getUserMonthlyFees(tenantId, userId).listen((fees) {
      _monthlyFees = fees;
      _isLoading = false;
      notifyListeners();
    });

    _repository.getUserBazaarDebts(tenantId, userId).listen((debts) {
      _bazaarDebts = debts;
      notifyListeners();
    });
  }

  // Admin Actions
  Future<void> syncCurrentYear(String userId, double defaultValue) async {
    final year = DateTime.now().year;
    await _repository.syncMonthlyFeesForYear(userId, year, defaultValue);
  }

  Future<void> updateStatus(
    String userId,
    String feeId,
    FinanceStatus status, {
    double? value,
  }) async {
    await _repository.updateMonthlyFeeStatus(
      userId,
      feeId,
      status,
      value: value,
    );
  }

  Future<void> payDebt(String userId, String debtId) async {
    await _repository.markBazaarDebtAsPaid(userId, debtId);
  }

  // Reminders
  Future<void> sendFeeReminder(UserModel user, String month) async {
    if (user.fcmTokens == null || user.fcmTokens!.isEmpty) return;
    await _pushService.notifyLateFee(
      userName: user.name.split(' ')[0],
      userTokens: user.fcmTokens!,
      month: month,
    );
  }

  Future<void> sendBazaarReminder(UserModel user, String itemName) async {
    if (user.fcmTokens == null || user.fcmTokens!.isEmpty) return;
    await _pushService.notifyBazaarDebt(
      userName: user.name.split(' ')[0],
      userTokens: user.fcmTokens!,
      itemName: itemName,
    );
  }
}
