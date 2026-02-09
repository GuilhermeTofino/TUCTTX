import 'dart:io';
import 'package:flutter/material.dart';
import '../../../domain/repositories/cambone_repository.dart';
import '../../../../core/services/ai_event_parser.dart';
import '../../../domain/models/cambone_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/work_event_model.dart'; // Added
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/event_repository.dart'; // Added
import '../../../core/di/service_locator.dart';

import 'package:intl/intl.dart';
import '../../../core/services/push_trigger_service.dart';

class CamboneViewModel extends ChangeNotifier {
  final AIEventParser _aiParser;
  final CamboneRepository _repository;
  final PushTriggerService _pushService; // Added
  final UserRepository _userRepository = getIt<UserRepository>();

  CamboneViewModel(
    this._aiParser,
    this._repository,
    this._pushService,
  ); // Updated constructor

  List<CamboneSchedule> _schedules = [];
  List<CamboneAssignment> _previewAssignments = [];
  List<UserModel> _users = [];
  List<WorkEvent> _availableEvents = []; // Eventos disponíveis para seleção
  WorkEvent? _selectedEvent; // Evento selecionado
  bool _isLoading = false;
  String? _error;

  List<CamboneSchedule> get schedules => _schedules;
  List<CamboneAssignment> get previewAssignments => _previewAssignments;
  List<UserModel> get users => _users;
  List<WorkEvent> get availableEvents => _availableEvents;
  WorkEvent? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? _editingScheduleId;

  // --- Actions ---

  void moveMedium(String mediumName, int sourceIndex, int targetIndex) {
    if (sourceIndex == targetIndex) return;

    final sourceAssignment = _previewAssignments[sourceIndex];
    final targetAssignment = _previewAssignments[targetIndex];

    // Remove do cambone de origem
    final updatedSourceMediums = List<String>.from(sourceAssignment.mediums)
      ..remove(mediumName);
    _previewAssignments[sourceIndex] = sourceAssignment.copyWith(
      mediums: updatedSourceMediums,
    );

    // Adiciona ao cambone de destino
    final updatedTargetMediums = List<String>.from(targetAssignment.mediums)
      ..add(mediumName);
    _previewAssignments[targetIndex] = targetAssignment.copyWith(
      mediums: updatedTargetMediums,
    );

    notifyListeners();
  }

  Future<void> fetchSchedules(String tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_users.isEmpty) {
        _users = await _userRepository.getAllUsers();
      }
      _schedules = await _repository.getSchedules(tenantId);
      await fetchUpcomingEvents(tenantId); // Carrega eventos também
    } catch (e) {
      _error = "Erro ao buscar escalas: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingEvents(String tenantId) async {
    try {
      final eventRepository = getIt<EventRepository>();
      _availableEvents = await eventRepository.getEventsByTenant(tenantId);
      notifyListeners();
    } catch (e) {
      print("Erro ao buscar eventos: $e");
    }
  }

  void selectEvent(WorkEvent? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  // Helper para buscar usuário pelo nome (case insensitive)
  UserModel? findUserByName(String name) {
    if (name.isEmpty) return null;
    try {
      final normalizedInput = name.toLowerCase().trim();
      return _users.firstWhere(
        (u) =>
            u.name.toLowerCase().trim().contains(normalizedInput) ||
            normalizedInput.contains(u.name.toLowerCase().trim()),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> importFromText(String text) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiParser.parseCamboneScheduleText(text);
      _previewAssignments = result
          .map((e) => CamboneAssignment.fromMap(e))
          .toList();
    } catch (e) {
      _error = "Erro na importação: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importFromImage(File image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiParser.parseCamboneScheduleImage(image);
      _previewAssignments = result
          .map((e) => CamboneAssignment.fromMap(e))
          .toList();
    } catch (e) {
      _error = "Erro na importação: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Prepara o ViewModel para edição de uma escala existente
  void loadForEdit(CamboneSchedule schedule) {
    _previewAssignments = List.from(schedule.assignments);
    _editingScheduleId = schedule.id;

    // Tenta encontrar o evento correspondente na lista
    if (schedule.eventId != null) {
      _selectedEvent = _availableEvents
          .where((e) => e.id == schedule.eventId)
          .firstOrNull;
    }
    // Se não tiver eventId (legado ou manual), tenta bater data?
    // Por enquanto deixamos nulo se não achar o ID.

    notifyListeners();
  }

  Future<void> saveSchedule(DateTime date, String tenantId) async {
    // Agora validamos se tem Assignments E se tem evento selecionado
    if (_previewAssignments.isEmpty) {
      _error = "A lista de cambones está vazia.";
      notifyListeners();
      return;
    }

    if (_selectedEvent == null) {
      _error = "Selecione um evento para esta escala.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Usa a data e título do evento selecionado
      final finalDate = _selectedEvent!.date;
      final eventId = _selectedEvent!.id;
      final eventTitle = _selectedEvent!.title;

      final schedule = CamboneSchedule(
        id: _editingScheduleId ?? '',
        date: finalDate,
        assignments: _previewAssignments,
        eventId: eventId,
        eventTitle: eventTitle,
      );

      await _repository.saveSchedule(schedule, tenantId);

      final dateFormatted = DateFormat(
        "d 'de' MMMM",
        'pt_BR',
      ).format(finalDate);
      final notificationTitle = "$eventTitle ($dateFormatted)";

      // Notifica se for novo OU edição
      if (_editingScheduleId == null || _editingScheduleId!.isEmpty) {
        await _pushService.notifyNewCamboneSchedule(notificationTitle);
      } else {
        await _pushService.notifyUpdatedCamboneSchedule(notificationTitle);
      }

      clearPreview();
      await fetchSchedules(tenantId);
    } catch (e) {
      _error = "Erro ao salvar: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String scheduleId, String tenantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Busca a escala antes de deletar para pegar o título do evento (se possível)
      final scheduleToDelete = _schedules
          .where((s) => s.id == scheduleId)
          .firstOrNull;

      await _repository.deleteSchedule(scheduleId, tenantId);

      if (scheduleToDelete != null) {
        final dateFormatted = DateFormat(
          "d/MM",
          'pt_BR',
        ).format(scheduleToDelete.date);
        final title = scheduleToDelete.eventTitle ?? "Dia $dateFormatted";
        await _pushService.notifyDeletedCamboneSchedule(title);
      }

      await fetchSchedules(tenantId);
    } catch (e) {
      _error = "Erro ao excluir: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPreview() {
    _previewAssignments = [];
    _editingScheduleId = null;
    _selectedEvent = null; // Limpa evento selecionado
    notifyListeners();
  }
}
