import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/study_document_model.dart';
import '../../domain/repositories/study_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseStudyRepository extends BaseFirestoreDataSource
    implements StudyRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<StudyDocumentModel>> getDocuments(
    String tenantId,
    String topicId,
  ) {
    return tenantCollection('studies')
        .where('topicId', isEqualTo: topicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => StudyDocumentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> uploadDocument(StudyDocumentModel document) async {
    try {
      await tenantCollection('studies').doc(document.id).set(document.toMap());
    } catch (e) {
      throw Exception("Erro ao salvar metadados do documento: $e");
    }
  }

  @override
  Future<void> deleteDocument(
    String tenantId,
    String documentId,
    String fileUrl,
  ) async {
    try {
      // 1. Deletar do Firestore
      await tenantDocument('studies', documentId).delete();

      // 2. Deletar do Storage (opcional se quiser limpar o arquivo)
      // Nota: extrair o path do Storage a partir da URL pode ser complexo,
      // mas se estivermos salvando com um padrão, podemos usar refFromURL.
      await _storage.refFromURL(fileUrl).delete();
    } catch (e) {
      throw Exception("Erro ao excluir documento: $e");
    }
  }
}
