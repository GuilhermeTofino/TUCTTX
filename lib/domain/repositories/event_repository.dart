import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<WorkEvent>> getEventsByTenant(String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('events')
          .where(
            'date',
            isGreaterThanOrEqualTo: DateTime.now(),
          ) // Apenas giras futuras
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) => WorkEvent.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception("Erro ao buscar eventos: $e");
    }
  }

  Future<void> addEvent(Map<String, dynamic> eventData, String tenantId) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('events')
          .add({
            'title': eventData['title'],
            'date': Timestamp.fromDate(DateTime.parse(eventData['date'])),
            'type': eventData['type'],
            'description': eventData['description'],
            'tenantId':
                tenantId, // Mantendo redundância se útil para queries futuras
            'cleaningCrew': eventData['cleaningCrew'], // Salva a lista de nomes
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception("Erro ao inserir no Firestore: $e");
    }
  }

  Future<void> confirmPresence(
    String tenantId,
    String eventId,
    dynamic user,
  ) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('events')
          .doc(eventId)
          .collection('confirmations')
          .doc(user.id)
          .set({
            'name': user.name,
            'photoUrl': user.photoUrl,
            'confirmedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception("Erro ao confirmar presença: $e");
    }
  }

  Future<void> removePresence(
    String tenantId,
    String eventId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('events')
          .doc(eventId)
          .collection('confirmations')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception("Erro ao remover presença: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getConfirmations(
    String tenantId,
    String eventId,
  ) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('events')
        .doc(eventId)
        .collection('confirmations')
        .orderBy('confirmedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
