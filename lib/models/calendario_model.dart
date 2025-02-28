import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarioModel {
  final String id;
  final String titulo;
  final DateTime data;
  final String descricao;
  final List<String> participantes;

  CalendarioModel({
    required this.id,
    required this.titulo,
    required this.data,
    required this.descricao,
    required this.participantes,
  });

  // Converte um documento do Firestore para um objeto CalendarioModel
  factory CalendarioModel.fromMap(Map<String, dynamic> map, String id) {
    return CalendarioModel(
      id: id,
      titulo: map['titulo'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      descricao: map['descricao'] ?? '',
      participantes: List<String>.from(map['participantes'] ?? []),
    );
  }

  // Converte o objeto para um mapa para ser salvo no Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'data': data,
      'descricao': descricao,
      'participantes': participantes,
    };
  }
}