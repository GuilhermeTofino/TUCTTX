import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/ai_event_parser.dart';
import '../../domain/repositories/event_repository.dart';

class ImportEventsViewModel extends ChangeNotifier {
  final AIEventParser _aiParser;
  final EventRepository _repository;

  ImportEventsViewModel(this._aiParser, this._repository);

  List<Map<String, dynamic>> _previewEvents = [];
  List<Map<String, dynamic>> get previewEvents => _previewEvents;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // 1. Processa o texto do WhatsApp com a IA
  Future<void> processText(String text) async {
    _isProcessing = true;
    notifyListeners();

    try {
      _previewEvents = await _aiParser.parseWhatsAppText(text);
    } catch (e) {
      debugPrint("Erro IA: $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // 1.1 Processa imagem (Escala de faxina/calendário)
  Future<void> processImage(File image) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final events = await _aiParser.parseImage(image);
      _previewEvents.addAll(
        events,
      ); // Adiciona aos existentes ou começa nova lista
    } catch (e) {
      debugPrint("Erro IA Imagem: $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // 2. Salva todos os eventos confirmados no Firebase
  Future<bool> saveEvents(String tenantId) async {
    if (_previewEvents.isEmpty) return false;

    _isProcessing = true; // Ativa o loading no botão
    notifyListeners();

    try {
      // Percorre cada evento que a IA gerou e salva no banco
      for (var eventMap in _previewEvents) {
        await _repository.addEvent(eventMap, tenantId);
      }

      _previewEvents = []; // Limpa a lista após o sucesso
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar eventos: $e");
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void removePreviewEvent(int index) {
    _previewEvents.removeAt(index);
    notifyListeners();
  }
}
