import 'package:flutter/material.dart';
import '../../domain/models/work_event_model.dart';
import '../../domain/repositories/event_repository.dart';

class CalendarViewModel extends ChangeNotifier {
  final EventRepository _repository;

  List<WorkEvent> _events = [];
  List<WorkEvent> get events => _events;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CalendarViewModel(this._repository);

  Future<void> loadEvents(String tenantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await _repository.getEventsByTenant(tenantId);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
    String tenantId,
  ) async {
    try {
      await _repository.updateEvent(eventId, eventData);
      await loadEvents(tenantId); // Recarrega para refletir mudanças
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteEvent(
    String eventId,
    String tenantId,
    String eventTitle,
  ) async {
    try {
      await _repository.deleteEvent(eventId, eventTitle);
      await loadEvents(tenantId); // Recarrega para refletir mudanças
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> confirmPresence(
    String tenantId,
    String eventId,
    dynamic user,
  ) async {
    try {
      await _repository.confirmPresence(tenantId, eventId, user);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> removePresence(
    String tenantId,
    String eventId,
    String userId,
  ) async {
    try {
      await _repository.removePresence(tenantId, eventId, userId);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Stream<List<Map<String, dynamic>>> getConfirmations(
    String tenantId,
    String eventId,
  ) {
    return _repository.getConfirmations(tenantId, eventId);
  }

  Future<void> toggleAttendance(
    String tenantId,
    String eventId,
    String memberName,
    bool isConfirmed,
  ) async {
    try {
      await _repository.toggleAttendanceConfirmation(
        eventId,
        memberName,
        isConfirmed,
      );
      await loadEvents(tenantId); // Recarrega para refletir a mudança de cor
    } catch (e) {
      debugPrint("Erro ao alternar presença: $e");
    }
  }
}
