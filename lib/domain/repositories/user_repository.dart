import '../models/user_model.dart';

abstract class UserRepository {
  /// Busca o perfil completo de um usuário pelo seu ID único (UID).
  /// Agora garantindo o retorno do campo 'role' para gestão de permissões.
  Future<UserModel?> getUserProfile(String uid);

  /// Salva ou atualiza os dados do perfil do usuário no banco de dados.
  /// Utilizado para atualizar fotos, dados de fundamento ou alteração de 'role'.
  Future<void> saveUserProfile(UserModel user);

  /// Lista todos os usuários vinculados ao Tenant atual (útil para gestão administrativa).
  Future<List<UserModel>> getAllUsers();

  /// Atualiza as datas de Amaci (último e próximo) de um usuário.
  Future<void> updateAmaciDates(
    String uid,
    DateTime? lastAmaci,
    DateTime? nextAmaci,
  );
}
