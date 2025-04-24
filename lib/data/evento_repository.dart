// lib/data/evento_repository.dart
import 'package:app_tenda/models/evento_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retorna um stream com a lista de eventos ordenados por data
  Stream<List<Evento>> getEventos() {
    return _firestore
        .collection('GiraMes')
        .orderBy('data')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Evento.fromSnapshot(doc)).toList());
  }

  // Retorna um único evento pelo id do documento
  Future<DocumentSnapshot> getEventoById(String documentId) {
    return _firestore.collection('GiraMes').doc(documentId).get();
  }

  // Atualiza a lista de presenças de um evento
  Future<void> updateEventoPresenca(String documentId, List<dynamic> presencas) async {
    await _firestore.collection('GiraMes').doc(documentId).update({'presencas': presencas});
  }

  // Adiciona um novo evento
  Future<DocumentReference> addEvento(Map<String, dynamic> eventData) async {
    return await _firestore.collection('GiraMes').add(eventData);
  }

  // Atualiza os dados de um evento
  Future<void> updateEvento(String documentId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('GiraMes').doc(documentId).update(updatedData);
  }

  // Exclui um evento
  Future<void> deleteEvento(String documentId) async {
    await _firestore.collection('GiraMes').doc(documentId).delete();
  }
}