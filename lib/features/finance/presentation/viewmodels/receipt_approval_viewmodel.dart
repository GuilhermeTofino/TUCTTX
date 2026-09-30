import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/pending_receipts_grouping.dart';
import 'package:app_tenda/features/finance/domain/repositories/payment_request_repository.dart';

/// Lado do aprovador: quem pode aprovar e a fila de comprovantes pendentes.
class ReceiptApprovalViewModel extends ChangeNotifier {
  final PaymentRequestRepository _repository = getIt<PaymentRequestRepository>();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _isApprover = false;
  bool get isApprover => _isApprover;

  String? _userId;
  List<PaymentRequestModel> _pending = [];
  StreamSubscription? _subscription;

  /// Pendências agrupadas por membro, sem as do próprio aprovador.
  List<UserPendingGroup> get groups =>
      groupPendingByUser(_pending, excludeUserId: _userId);

  int get pendingMonthCount =>
      groups.fold(0, (total, g) => total + g.months.length);

  UserPendingGroup? groupFor(String userId) {
    for (final g in groups) {
      if (g.userId == userId) return g;
    }
    return null;
  }

  /// Descobre se [user] é aprovador e, se for, passa a acompanhar a fila.
  Future<void> init(UserModel? user) async {
    _subscription?.cancel();
    _userId = user?.id;
    _isApprover = false;

    if (user != null && user.isAdmin) {
      try {
        final approvers = await _repository.getApproverIds();
        _isApprover = approvers.contains(user.id);
      } catch (_) {
        _isApprover = false;
      }
    }

    if (_isApprover) {
      _subscription = _repository.getPendingRequests().listen((data) {
        _pending = data;
        notifyListeners();
      });
    } else {
      _pending = [];
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<ReceiptFile?> loadReceipt(String path) =>
      _repository.downloadReceipt(path);

  void clear() {
    _subscription?.cancel();
    _pending = [];
    _isApprover = false;
    _isLoaded = false;
    _userId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
