import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);
  Future<void> signOut();
  Stream<UserModel?> get onAuthStateChanged;
}