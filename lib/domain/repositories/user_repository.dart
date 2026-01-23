import '../models/user_model.dart'; // Você criará este model simples

abstract class UserRepository {
  Future<UserModel?> getUserProfile(String uid);
  Future<void> saveUserProfile(UserModel user);
}