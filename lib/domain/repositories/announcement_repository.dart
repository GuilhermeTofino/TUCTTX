import '../models/announcement_model.dart';

abstract class AnnouncementRepository {
  Stream<List<AnnouncementModel>> getAnnouncements(String tenantId);
  Future<void> createAnnouncement(AnnouncementModel announcement);
  Future<void> deleteAnnouncement(String id);
}
