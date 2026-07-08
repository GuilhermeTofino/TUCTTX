import '../models/study_document_model.dart';

abstract class StudyRepository {
  Stream<List<StudyDocumentModel>> getDocuments(
    String tenantId,
    String topicId,
  );
  Future<void> uploadDocument(StudyDocumentModel document);
  Future<void> deleteDocument(
    String tenantId,
    String documentId,
    String fileUrl,
  );
}
