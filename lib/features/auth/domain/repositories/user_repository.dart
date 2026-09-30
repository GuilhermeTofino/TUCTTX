import 'package:app_tenda/features/profile/domain/models/entity_model.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/profile/domain/models/health_data_model.dart';

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

  /// Atualiza a lista de entidades ("Minhas Entidades") do usuário.
  Future<void> updateEntities(String uid, List<EntityModel> entities);

  /// Chaves que o próprio usuário pode editar no seu documento.
  /// Nunca inclui role, status nem skills (só admin muda; travado nas regras).
  static const Set<String> personalFields = {
    'name',
    'phone',
    'photoUrl',
    'endereco',
    'dataNascimento',
    'orixaFrente',
    'orixaJunto',
    // O consulente se cadastra só com o básico; estes o membro completa depois.
    'emergencyContact',
    'jaTirouSanto',
    'jogoComTata',
  };

  /// Atualiza SÓ os campos pessoais informados, sem regravar o perfil inteiro
  /// (que sobrescreveria tokens de push e papel com uma cópia antiga).
  /// Lança [ArgumentError] para qualquer chave fora de [personalFields].
  Future<void> updatePersonalFields(String uid, Map<String, dynamic> fields);

  /// Dados de saúde do usuário (subcoleção privada); null se ainda não existem.
  Future<HealthData?> getHealth(String uid);

  /// Grava os dados de saúde na subcoleção privada.
  Future<void> saveHealth(String uid, HealthData health);

  /// Consulente pede aprovação como membro: status active -> pending_approval.
  Future<void> requestApproval(String uid);
}
