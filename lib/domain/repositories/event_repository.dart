import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/base_firestore_datasource.dart';
import '../models/work_event_model.dart';

class EventRepository extends BaseFirestoreDataSource {
  Future<List<WorkEvent>> getEventsByTenant(String tenantId) async {
    try {
      final snapshot = await tenantCollection('events')
          .where('date', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) => WorkEvent.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception("Erro ao buscar eventos: $e");
    }
  }

  Future<void> addEvent(Map<String, dynamic> eventData, String tenantId) async {
    try {
      await tenantCollection('events').add({
        'title': eventData['title'],
        'date': Timestamp.fromDate(DateTime.parse(eventData['date'])),
        'type': eventData['type'],
        'description': eventData['description'],
        'tenantId': tenantId,
        'cleaningCrew': eventData['cleaningCrew'],
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
      await tenantCollection(
        'events',
      ).doc(eventId).collection('confirmations').doc(user.id).set({
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
      await tenantCollection(
        'events',
      ).doc(eventId).collection('confirmations').doc(userId).delete();
    } catch (e) {
      throw Exception("Erro ao remover presença: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getConfirmations(
    String tenantId,
    String eventId,
  ) {
    return tenantCollection('events')
        .doc(eventId)
        .collection('confirmations')
        .orderBy('confirmedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
