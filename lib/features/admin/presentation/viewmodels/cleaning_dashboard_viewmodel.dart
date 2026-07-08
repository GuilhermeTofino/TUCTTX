import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../core/di/service_locator.dart';

class CleaningMemberStats {
  final String name;
  final int attendanceCount;

  CleaningMemberStats({required this.name, required this.attendanceCount});
}

class CleaningDashboardViewModel extends ChangeNotifier {
  final EventRepository _repository = getIt<EventRepository>();
  StreamSubscription? _subscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CleaningMemberStats> _ranking = [];
  List<CleaningMemberStats> get ranking => _ranking;

  int _totalEvents = 0;
  int get totalEvents => _totalEvents;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.streamAllEvents().listen(
      (allEvents) {
        // Filtramos apenas eventos que possuem uma equipe de faxina definida
        final events = allEvents
            .where((e) => e.cleaningCrew != null && e.cleaningCrew!.isNotEmpty)
            .toList();

        _totalEvents = events.length;
        final Map<String, int> attendanceMap = {};

        for (var event in events) {
          if (event.confirmedAttendance != null) {
            for (var name in event.confirmedAttendance!) {
              // Só contamos se o nome estiver na equipe de faxina desse evento
              // (Segurança adicional caso o campo confirmedAttendance tenha nomes extras)
              if (event.cleaningCrew!.contains(name)) {
                attendanceMap[name] = (attendanceMap[name] ?? 0) + 1;
              }
            }
          }
        }

        _ranking = attendanceMap.entries
            .map(
              (e) => CleaningMemberStats(name: e.key, attendanceCount: e.value),
            )
            .toList();

        // Ordenar por maior comparecimento
        _ranking.sort((a, b) => b.attendanceCount.compareTo(a.attendanceCount));

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Erro ao carregar dashboard de faxina: $e");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
