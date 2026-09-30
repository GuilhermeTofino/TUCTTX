import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';
import 'package:app_tenda/features/finance/domain/models/financial_models.dart';
import 'package:app_tenda/features/finance/domain/payment_decision.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';

abstract class PaymentRequestRepository {
  /// Solicitações do próprio membro, da mais recente para a mais antiga.
  Stream<List<PaymentRequestModel>> getUserRequests(String userId);

  /// Envia o comprovante para o Storage e devolve o caminho do arquivo.
  Future<String> uploadReceipt({
    required File file,
    required String userId,
    required String requestId,
    required int year,
    required String contentType,
  });

  Future<void> createRequest(PaymentRequestModel request);

  /// Uma solicitação pelo id; null se não existir.
  Future<PaymentRequestModel?> getRequest(String requestId);

  /// Ids dos admins marcados como aprovadores do financeiro.
  Future<List<String>> getApproverIds();

  /// Inclui ou remove [userId] da lista de aprovadores. Altera só esse id
  /// (arrayUnion/arrayRemove), sem regravar a lista inteira.
  Future<void> setApprover(String userId, {required bool enabled});

  /// Solicitações com algum mês ainda aguardando decisão (todas as pessoas).
  Stream<List<PaymentRequestModel>> getPendingRequests();

  /// Baixa o comprovante pelo caminho do Storage (leitura autenticada, sem
  /// link público). Null se o arquivo não existir mais (ex.: limpeza anual).
  Future<ReceiptFile?> downloadReceipt(String path);

  /// Aprova ou rejeita um mês, em transação: atualiza a solicitação e, se
  /// aprovado, baixa a mensalidade como paga. Lança [StateError] se o mês já
  /// foi decidido (ex.: por outro aprovador) e [ArgumentError] para dados
  /// inválidos.
  Future<void> decideItem({
    required String requestId,
    required int month,
    required int year,
    required bool approve,
    required String approverId,
    double? correctedValue,
    String? rejectReason,
  });
}

class ReceiptFile {
  final Uint8List bytes;
  final String contentType;
  const ReceiptFile(this.bytes, this.contentType);

  bool get isPdf => contentType == 'application/pdf';
}

class FirebasePaymentRequestRepository extends BaseFirestoreDataSource
    implements PaymentRequestRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<PaymentRequestModel>> getUserRequests(String userId) {
    // Sem orderBy no servidor para não exigir índice composto; ordena aqui.
    return tenantCollection(
      'payment_requests',
    ).where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map(
            (doc) => PaymentRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
      requests.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );
      return requests;
    });
  }

  @override
  Future<String> uploadReceipt({
    required File file,
    required String userId,
    required String requestId,
    required int year,
    required String contentType,
  }) async {
    // Mesmo caminho que storage.rules libera para o dono do comprovante:
    // environments/{env}/tenants/{tenant}/receipts/{year}/{userId}/{requestId}
    final path = '${tenantRoot.path}/receipts/$year/$userId/$requestId';
    await _storage
        .ref()
        .child(path)
        .putFile(file, SettableMetadata(contentType: contentType));
    return path;
  }

  @override
  Future<void> createRequest(PaymentRequestModel request) async {
    await tenantDocument(
      'payment_requests',
      request.id,
    ).set(request.toMap());
  }

  @override
  Future<PaymentRequestModel?> getRequest(String requestId) async {
    final doc = await tenantDocument('payment_requests', requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PaymentRequestModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  @override
  Stream<List<PaymentRequestModel>> getPendingRequests() {
    // 'pending_approval' vale enquanto houver mês sem decisão (ver overallStatus).
    return tenantCollection('payment_requests')
        .where('status', isEqualTo: PaymentRequestStatus.pendingApproval.value)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PaymentRequestModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<ReceiptFile?> downloadReceipt(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final bytes = await ref.getData(5 * 1024 * 1024);
      if (bytes == null) return null;
      final metadata = await ref.getMetadata();
      return ReceiptFile(bytes, metadata.contentType ?? 'image/jpeg');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  @override
  Future<void> decideItem({
    required String requestId,
    required int month,
    required int year,
    required bool approve,
    required String approverId,
    double? correctedValue,
    String? rejectReason,
  }) async {
    final requestRef = tenantDocument('payment_requests', requestId);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(requestRef);
      if (!snap.exists) throw StateError('request-not-found');
      final request = PaymentRequestModel.fromMap(
        snap.data() as Map<String, dynamic>,
        snap.id,
      );
      if (request.userId == approverId) throw StateError('own-request');

      // Relê o estado dentro da transação: se outro aprovador decidiu o mês
      // antes, applyDecision lança 'item-already-decided'.
      final items = applyDecision(
        request.items,
        month: month,
        year: year,
        approve: approve,
        approverId: approverId,
        now: DateTime.now(),
        correctedValue: correctedValue,
        rejectReason: rejectReason,
      );

      tx.update(requestRef, {
        'items': items.map((i) => i.toMap()).toList(),
        'status': overallStatus(items).value,
      });

      if (approve) {
        final decided = items.firstWhere(
          (i) => i.month == month && i.year == year,
        );
        final feeRef = tenantCollection('financial')
            .doc(request.userId)
            .collection('monthly_fees')
            .doc(decided.feeId);
        // paidAt = data em que o membro pagou (base da contabilidade).
        tx.set(feeRef, {
          'userId': request.userId,
          'month': decided.month,
          'year': decided.year,
          'value': decided.value,
          'status': FinanceStatus.paid.name,
          'paidAt': Timestamp.fromDate(request.paidDate),
          'updatedAt': FieldValue.serverTimestamp(),
          'paymentRequestId': requestId,
          'approvedBy': approverId,
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<void> setApprover(String userId, {required bool enabled}) async {
    await tenantDocument('settings', 'finance').set({
      'approverIds': enabled
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<String>> getApproverIds() async {
    final doc = await tenantDocument('settings', 'finance').get();
    final data = doc.data() as Map<String, dynamic>?;
    return List<String>.from(data?['approverIds'] ?? const []);
  }
}
