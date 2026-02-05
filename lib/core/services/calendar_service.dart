import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:device_calendar/device_calendar.dart' as dev_cal;
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../domain/models/work_event_model.dart';

class CalendarService {
  final dev_cal.DeviceCalendarPlugin _deviceCalendarPlugin =
      dev_cal.DeviceCalendarPlugin();

  Future<void> addToCalendar(WorkEvent event) async {
    final Event calendarEvent = Event(
      title: event.title,
      description: event.description ?? '',
      location: 'Tenda',
      startDate: event.date,
      endDate: event.date.add(const Duration(hours: 4)),
      allDay: false,
    );

    try {
      await Add2Calendar.addEvent2Cal(calendarEvent);
    } catch (e) {
      debugPrint('Error adding to calendar: $e');
    }
  }

  Future<Map<String, dynamic>> addAllToCalendar(List<WorkEvent> events) async {
    try {
      // 1. Request Permissions
      var permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return {'success': false, 'message': 'Permissão negada'};
        }
      }

      // 2. Get Calendars
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data!.isEmpty) {
        return {'success': false, 'message': 'Nenhum calendário encontrado'};
      }

      // Try to find a default editable calendar or use the first one
      dev_cal.Calendar? targetCalendar;
      // Try to find a default calendar
      targetCalendar = calendarsResult.data!.firstWhere(
        (c) => c.isDefault == true && (c.isReadOnly == false),
        orElse: () => calendarsResult.data!.firstWhere(
          (c) => c.isReadOnly == false,
          orElse: () => calendarsResult.data!.first,
        ),
      );

      if (targetCalendar.isReadOnly == true) {
        return {
          'success': false,
          'message': 'Nenhum calendário editável encontrado',
        };
      }

      int successCount = 0;
      int errorCount = 0;

      // 3. Add Events
      for (final event in events) {
        final dev_cal.Event calendarEvent = dev_cal.Event(
          targetCalendar.id,
          title: event.title,
          description: event.description,
          start: tz.TZDateTime.from(event.date, tz.local),
          end: tz.TZDateTime.from(
            event.date.add(const Duration(hours: 4)),
            tz.local,
          ),
          location: 'Tenda',
        );

        final result = await _deviceCalendarPlugin.createOrUpdateEvent(
          calendarEvent,
        );
        if (result?.isSuccess == true) {
          successCount++;
        } else {
          errorCount++;
        }
      }

      if (successCount == 0 && errorCount > 0) {
        return {'success': false, 'message': 'Erro ao exportar eventos.'};
      }

      return {'success': true, 'message': '$successCount eventos exportados!'};
    } catch (e) {
      debugPrint("Erro na exportação em lote: $e");
      return {'success': false, 'message': 'Erro ao exportar: $e'};
    }
  }
}
