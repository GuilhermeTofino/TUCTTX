import 'package:cloud_firestore/cloud_firestore.dart';

class CamboneAssignment {
  final String camboneName;
  final List<String> mediums;

  CamboneAssignment({required this.camboneName, required this.mediums});

  Map<String, dynamic> toMap() {
    return {'camboneName': camboneName, 'mediums': mediums};
  }

  factory CamboneAssignment.fromMap(Map<String, dynamic> map) {
    return CamboneAssignment(
      camboneName: map['camboneName'] ?? '',
      mediums: List<String>.from(map['mediums'] ?? []),
    );
  }

  CamboneAssignment copyWith({String? camboneName, List<String>? mediums}) {
    return CamboneAssignment(
      camboneName: camboneName ?? this.camboneName,
      mediums: mediums ?? this.mediums,
    );
  }
}

class CamboneSchedule {
  final String id;
  final DateTime date;
  final List<CamboneAssignment> assignments;
  final String? eventId; // ID do evento vinculado
  final String? eventTitle; // Título do evento para exibição

  CamboneSchedule({
    required this.id,
    required this.date,
    required this.assignments,
    this.eventId,
    this.eventTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'assignments': assignments.map((x) => x.toMap()).toList(),
      'eventId': eventId,
      'eventTitle': eventTitle,
    };
  }

  factory CamboneSchedule.fromMap(Map<String, dynamic> map, String id) {
    return CamboneSchedule(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      assignments: List<CamboneAssignment>.from(
        (map['assignments'] as List<dynamic>).map<CamboneAssignment>(
          (x) => CamboneAssignment.fromMap(x as Map<String, dynamic>),
        ),
      ),
      eventId: map['eventId'],
      eventTitle: map['eventTitle'],
    );
  }
}
