import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_tenda/domain/models/financial_goal_model.dart';
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

  StreamSubscription? _monthlyFeesSubscription;
  StreamSubscription? _bazaarDebtsSubscription;

  void listenToFinancialData(String tenantId, String userId) {
    // Cancela assinaturas anteriores se existirem
    _monthlyFeesSubscription?.cancel();
    _bazaarDebtsSubscription?.cancel();

    // Notifica em microtask para evitar setState durante build
    Future.microtask(() {
      _isLoading = true;
      notifyListeners();
    });

    _monthlyFeesSubscription = _repository
        .getUserMonthlyFees(tenantId, userId)
        .listen((fees) {
          _monthlyFees = fees;
          _isLoading = false;
          notifyListeners();
        });

    _bazaarDebtsSubscription = _repository
        .getUserBazaarDebts(tenantId, userId)
        .listen((debts) {
          _bazaarDebts = debts;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _monthlyFeesSubscription?.cancel();
    _bazaarDebtsSubscription?.cancel();
    _goalsSubscription?.cancel();
    super.dispose();
  }

  void clear() {
    _monthlyFeesSubscription?.cancel();
    _bazaarDebtsSubscription?.cancel();
    _goalsSubscription?.cancel();
    _monthlyFees = [];
    _bazaarDebts = [];
    _goals = [];
    notifyListeners();
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

  // Goals Logic
  List<FinancialGoalModel> _goals = [];
  List<FinancialGoalModel> get goals => _goals;
  StreamSubscription? _goalsSubscription;

  void listenToGoals(String tenantId, int year) {
    _goalsSubscription?.cancel();
    _goalsSubscription = _repository.getGoals(tenantId, year).listen((data) {
      _goals = data;
      notifyListeners();
    });
  }

  Future<void> saveGoal(FinancialGoalModel goal) async {
    await _repository.saveGoal(goal);
  }

  double getMonthlyGoal(int month, int year) {
    final goal = _goals.firstWhere(
      (g) =>
          g.year == year &&
          g.month == month &&
          g.type == FinancialGoalType.monthly,
      orElse: () => FinancialGoalModel(
        id: '',
        tenantId: '',
        type: FinancialGoalType.monthly,
        year: year,
        targetValue: 0,
        updatedAt: DateTime.now(),
      ),
    );
    return goal.targetValue;
  }

  double getAnnualGoal(int year) {
    final goal = _goals.firstWhere(
      (g) => g.year == year && g.type == FinancialGoalType.annual,
      orElse: () => FinancialGoalModel(
        id: '',
        tenantId: '',
        type: FinancialGoalType.annual,
        year: year,
        targetValue: 0,
        updatedAt: DateTime.now(),
      ),
    );
    return goal.targetValue;
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
