// lib/model/evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Evento {
  final String id;
  final DateTime data;
  final String titulo;
  final String descricao;
  final String tag;
  final List<dynamic> presencas;

  Evento({
    required this.id,
    required this.data,
    required this.titulo,
    required this.descricao,
    required this.tag,
    required this.presencas,
  });

  factory Evento.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Evento(
      id: snapshot.id,
      data: (data['data'] as Timestamp).toDate(),
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      tag: data['tag'] ?? '',
      presencas: data['presencas'] ?? [],
    );
  }

  String get formattedDate {
    return DateFormat('dd/MM').format(data);
  }
}