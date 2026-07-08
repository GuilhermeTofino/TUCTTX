abstract class NotificationRepository {
  Future<void> saveToken(String userId, String token);
  Future<void> removeToken(String userId, String token);
}
