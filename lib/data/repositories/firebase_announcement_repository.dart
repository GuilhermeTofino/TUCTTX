import '../../domain/models/announcement_model.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseAnnouncementRepository extends BaseFirestoreDataSource
    implements AnnouncementRepository {
  @override
  Stream<List<AnnouncementModel>> getAnnouncements(String tenantId) {
    return tenantCollection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AnnouncementModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    try {
      // Se tiver ID, usa ele. Se nao, o add gera.
      if (announcement.id.isNotEmpty) {
        await tenantDocument(
          'announcements',
          announcement.id,
        ).set(announcement.toMap());
      } else {
        await tenantCollection('announcements').add(announcement.toMap());
      }
    } catch (e) {
      throw Exception("Erro ao criar aviso: $e");
    }
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await tenantDocument('announcements', id).delete();
    } catch (e) {
      throw Exception("Erro ao excluir aviso: $e");
    }
  }
}
