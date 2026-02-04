import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../domain/models/study_document_model.dart';
import '../../../domain/repositories/study_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';
import 'package:uuid/uuid.dart';

class StudyViewModel extends ChangeNotifier {
  final StudyRepository _repository = getIt<StudyRepository>();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Mapa de streams para cada tópico
  final Map<String, Stream<List<StudyDocumentModel>>> _documentStreams = {};

  Stream<List<StudyDocumentModel>> getDocumentsStream(String topicId) {
    if (!_documentStreams.containsKey(topicId)) {
      _documentStreams[topicId] = _repository.getDocuments(
        AppConfig.instance.tenant.tenantSlug,
        topicId,
      );
    }
    return _documentStreams[topicId]!;
  }

  Future<void> uploadPdf({
    required String topicId,
    required String title,
    required File file,
    required String authorId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final env = AppConfig.instance.environment == AppEnvironment.dev
          ? 'dev'
          : 'prod';
      final tenantId = AppConfig.instance.tenant.tenantSlug;
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.pdf";
      final storagePath =
          "environments/$env/tenants/$tenantId/studies/$topicId/$fileName";

      // 1. Upload para o Storage
      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Salvar no Firestore
      final document = StudyDocumentModel(
        id: const Uuid().v4(),
        topicId: topicId,
        title: title,
        fileUrl: downloadUrl,
        createdAt: DateTime.now(),
        authorId: authorId,
      );

      await _repository.uploadDocument(document);
    } catch (e) {
      _errorMessage = "Erro ao fazer upload: $e";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDocument(StudyDocumentModel document) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteDocument(
        AppConfig.instance.tenant.tenantSlug,
        document.id,
        document.fileUrl,
      );
    } catch (e) {
      _errorMessage = "Erro ao excluir: $e";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
