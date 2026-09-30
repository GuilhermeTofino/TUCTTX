import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/finance/domain/models/financial_models.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/receipt_submission_validator.dart';
import 'package:app_tenda/features/finance/domain/repositories/payment_request_repository.dart';

class PaymentRequestViewModel extends ChangeNotifier {
  static const int maxReceiptBytes = 5 * 1024 * 1024;

  final PaymentRequestRepository _repository = getIt<PaymentRequestRepository>();

  List<PaymentRequestModel> _requests = [];
  List<PaymentRequestModel> get requests => _requests;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  StreamSubscription? _requestsSubscription;

  void listenToRequests(String userId) {
    _requestsSubscription?.cancel();
    _requestsSubscription = _repository.getUserRequests(userId).listen((data) {
      _requests = data;
      notifyListeners();
    });
  }

  /// Solicitações que ainda aguardam decisão do financeiro.
  List<PaymentRequestModel> get openRequests => _requests
      .where((r) => r.status == PaymentRequestStatus.pendingApproval)
      .toList();

  /// Meses (`ano_mes`) com comprovante em análise, para sinalizar na lista.
  Set<String> get monthsUnderReview => {
    for (final r in openRequests)
      for (final i in r.items)
        if (i.status == PaymentItemStatus.pendingApproval) i.feeId,
  };

  void clear() {
    _requestsSubscription?.cancel();
    _requests = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  /// Valida, envia o arquivo e cria a solicitação.
  /// Retorna a mensagem de erro, ou null em caso de sucesso.
  Future<String?> submit({
    required UserModel user,
    required List<PaymentRequestItem> items,
    required double? totalValue,
    required DateTime? paidDate,
    required File? file,
    required String? fileName,
    required String? message,
    required List<MonthlyFeeModel> fees,
  }) async {
    final error = ReceiptSubmissionValidator.validate(
      items: items,
      totalValue: totalValue,
      paidDate: paidDate,
      hasFile: file != null && fileName != null,
      fees: fees,
      openRequests: openRequests,
    );
    if (error != null) return error;

    final contentType = ReceiptSubmissionValidator.contentTypeFor(fileName!);
    if (contentType == null) {
      return 'Formato não suportado. Envie imagem (JPG/PNG) ou PDF.';
    }
    if (await file!.length() > maxReceiptBytes) {
      return 'O comprovante deve ter no máximo 5 MB.';
    }

    _isSubmitting = true;
    notifyListeners();
    try {
      final requestId = const Uuid().v4();
      final path = await _repository.uploadReceipt(
        file: file,
        userId: user.id,
        requestId: requestId,
        year: PaymentRequestModel.receiptYearFor(items),
        contentType: contentType,
      );

      // A solicitação só existe depois do upload; se ele falhar nada é criado.
      await _repository.createRequest(
        PaymentRequestModel(
          id: requestId,
          userId: user.id,
          userName: user.name,
          items: items,
          totalValue: totalValue!,
          paidDate: paidDate!,
          message: (message == null || message.trim().isEmpty)
              ? null
              : message.trim(),
          receiptPath: path,
        ),
      );
      return null;
    } catch (e) {
      return 'Não foi possível enviar o comprovante. Tente novamente.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
