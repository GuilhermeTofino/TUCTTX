import '../models/user_model.dart';

abstract class UserRepository {
  /// Busca o perfil completo de um usuário pelo seu ID único (UID).
  Future<UserModel?> getUserProfile(String uid);

  /// Salva ou atualiza os dados do perfil do usuário no banco de dados.
  Future<void> saveUserProfile(UserModel user);
}