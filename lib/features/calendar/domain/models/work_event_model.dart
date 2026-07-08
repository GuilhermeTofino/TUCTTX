import 'package:cloud_firestore/cloud_firestore.dart';

class WorkEvent {
  final String id;
  final String title;
  final DateTime date;
  final String type; // Ex: 'Pública', 'Fechada', 'Festa'
  final String? description;
  final String tenantId;
  final List<String>? cleaningCrew; // Lista de nomes para a faxina
  final List<String>? confirmedAttendance; // Nomes confirmados pelo admin
  final List<String>? participants; // Participantes gerais (ex: Amaci)

  WorkEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.description,
    required this.tenantId,
    this.cleaningCrew,
    this.confirmedAttendance,
    this.participants,
  });

  // Converte os dados do Firebase para o nosso modelo
  factory WorkEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WorkEvent(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'Pública',
      description: data['description'],
      tenantId: data['tenantId'] ?? '',
      cleaningCrew: data['cleaningCrew'] != null
          ? List<String>.from(data['cleaningCrew'])
          : null,
      confirmedAttendance: data['confirmedAttendance'] != null
          ? List<String>.from(data['confirmedAttendance'])
          : [],
      participants: data['participants'] != null
          ? List<String>.from(data['participants'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'type': type,
      'description': description,
      'tenantId': tenantId,
      'cleaningCrew': cleaningCrew,
      'confirmedAttendance': confirmedAttendance,
      'participants': participants,
    };
  }
}
