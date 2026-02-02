import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseNotificationRepository extends BaseFirestoreDataSource
    implements NotificationRepository {
  @override
  Future<void> saveToken(String userId, String token) async {
    try {
      await tenantDocument('users', userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // Se o documento não existir ou falhar o update, tentamos um set com merge
      await tenantDocument('users', userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> removeToken(String userId, String token) async {
    try {
      await tenantDocument('users', userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      // Silenciar erro se o documento não existir
    }
  }
}
