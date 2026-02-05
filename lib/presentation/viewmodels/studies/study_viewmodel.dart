import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../domain/models/study_document_model.dart';
import '../../../domain/repositories/study_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/push_trigger_service.dart';
import 'package:uuid/uuid.dart';

class StudyViewModel extends ChangeNotifier {
  final StudyRepository _repository = getIt<StudyRepository>();
  final PushTriggerService _pushService = getIt<PushTriggerService>();
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
    String? folder,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final env = AppConfig.instance.environment == AppEnvironment.dev
          ? 'dev'
          : 'prod';
      final tenantId = AppConfig.instance.tenant.tenantSlug;
      final extension = file.path.split('.').last.toLowerCase();
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$extension";
      final storagePath =
          "environments/$env/tenants/$tenantId/studies/$topicId/$fileName";

      String contentType = 'application/pdf';
      if (['mp3', 'mpeg'].contains(extension)) {
        contentType = 'audio/mpeg';
      } else if (['wav', 'x-wav'].contains(extension)) {
        contentType = 'audio/wav';
      } else if (['m4a', 'mp4'].contains(extension)) {
        contentType = 'audio/mp4';
      }

      // 1. Upload para o Storage
      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
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
        folder: folder,
      );

      await _repository.uploadDocument(document);

      // 3. Enviar notificação push
      // Tenta obter o nome amigável do tópico (isso poderia ser otimizado)
      String topicName = topicId;
      if (topicId == 'apostila')
        topicName = 'Apostila';
      else if (topicId == 'rumbe')
        topicName = 'Rumbê';
      else if (topicId == 'pontos_cantados')
        topicName = 'Pontos Cantados';
      else if (topicId == 'pontos_riscados')
        topicName = 'Pontos Riscados';
      else if (topicId == 'faq')
        topicName = 'FAQ';
      else if (topicId == 'ervas')
        topicName = 'Ervas';
      else if (topicId == 'atabaque')
        topicName = 'Atabaque';
      else if (topicId == 'biblioteca')
        topicName = 'Biblioteca';

      await _pushService.notifyNewStudyMaterial(
        topicName: topicName,
        title: title,
        folder: folder ?? '',
      );

      print('Upload realizado com sucesso: ${document.toMap()}');
    } catch (e) {
      _errorMessage = "Erro ao fazer upload: $e";
      print(_errorMessage);
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
