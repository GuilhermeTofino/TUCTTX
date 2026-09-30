import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
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

  /// Aprova ([approve]) ou rejeita um mês. Retorna a mensagem de erro, ou
  /// null em caso de sucesso.
  Future<String?> decide({
    required PaymentRequestModel request,
    required PaymentRequestItem item,
    required bool approve,
    double? correctedValue,
    String? rejectReason,
  }) async {
    final approverId = _userId;
    if (approverId == null) return 'Sessão expirada. Entre novamente.';

    try {
      await _repository.decideItem(
        requestId: request.id,
        month: item.month,
        year: item.year,
        approve: approve,
        approverId: approverId,
        correctedValue: correctedValue,
        rejectReason: rejectReason,
      );
    } on StateError catch (e) {
      switch (e.message) {
        case 'item-already-decided':
          return 'Este mês já foi decidido por outro aprovador.';
        case 'own-request':
          return 'Você não pode aprovar o próprio comprovante.';
        case 'request-not-found':
          return 'Esta solicitação não foi encontrada.';
        default:
          return 'Não foi possível concluir a decisão. Tente novamente.';
      }
    } on ArgumentError catch (e) {
      return e.message.toString();
    } catch (_) {
      return 'Não foi possível concluir a decisão. Tente novamente.';
    }

    // A decisão já foi gravada; falha no aviso não deve desfazê-la.
    await _notifyMember(request, item, approve, rejectReason);
    return null;
  }

  Future<void> _notifyMember(
    PaymentRequestModel request,
    PaymentRequestItem item,
    bool approve,
    String? reason,
  ) async {
    try {
      final member = await getIt<UserRepository>().getUserProfile(
        request.userId,
      );
      final tokens = member?.fcmTokens;
      if (member == null || tokens == null || tokens.isEmpty) return;

      final name = DateFormat('MMMM', 'pt_BR').format(DateTime(2024, item.month));
      await getIt<PushTriggerService>().notifyReceiptDecision(
        userName: member.name.split(' ')[0],
        userTokens: tokens,
        month: '${name[0].toUpperCase()}${name.substring(1)}/${item.year}',
        approved: approve,
        reason: reason?.trim(),
      );
    } catch (_) {
      // Melhor esforço: o membro ainda vê o resultado na lista de mensalidades.
    }
  }

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
