import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';
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
  Future<List<String>> getApproverIds() async {
    final doc = await tenantDocument('settings', 'finance').get();
    final data = doc.data() as Map<String, dynamic>?;
    return List<String>.from(data?['approverIds'] ?? const []);
  }
}
