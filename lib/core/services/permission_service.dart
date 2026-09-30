import 'package:app_tenda/features/auth/domain/models/user_model.dart';

/// Regras de "quem pode o quê" no app. Espelha as helpers de firestore.rules
/// (`isMember`, `hasSkill`): a tela decide o que mostrar, e as regras é que
/// garantem de fato. Mudou aqui? Confira firestore.rules e storage.rules.
///
/// - admin: todas as skills.
/// - user (filho de santo): só as skills da própria lista.
/// - visitor: nenhuma skill; só vê o calendário.
class PermissionService {
  static const String calendarManage = 'calendario.gerenciar';
  static const String bulletinPost = 'mural.publicar';
  static const String studiesManage = 'estudos.gerenciar';
  static const String financialManage = 'financeiro.gerenciar';
  static const String bazaarManage = 'bazar.gerenciar';
  static const String cleaningManage = 'limpeza.gerenciar';
  static const String entitiesModerate = 'entidades.moderar';
  static const String notificationsNotify = 'notificacoes.enviar';

  /// Todas as skills, na ordem em que aparecem para o admin marcar.
  static const List<String> allSkills = [
    calendarManage,
    bulletinPost,
    studiesManage,
    financialManage,
    bazaarManage,
    cleaningManage,
    entitiesModerate,
    notificationsNotify,
  ];

  /// Rótulos padrão; usados quando `skills_catalog` ainda não foi preenchido.
  static const Map<String, String> skillLabels = {
    calendarManage: 'Gerenciar calendário',
    bulletinPost: 'Publicar no mural',
    studiesManage: 'Gerenciar estudos',
    financialManage: 'Gerenciar financeiro',
    bazaarManage: 'Gerenciar bazar',
    cleaningManage: 'Gerenciar limpeza',
    entitiesModerate: 'Moderar entidades',
    notificationsNotify: 'Enviar notificações',
  };

  bool hasSkill(UserModel user, String skillKey) {
    if (user.role == 'admin') return true;
    if (user.role == 'user') return user.skills.contains(skillKey);
    return false;
  }

  bool canManageCalendar(UserModel user) => hasSkill(user, calendarManage);
  bool canPostBulletin(UserModel user) => hasSkill(user, bulletinPost);
  bool canManageStudies(UserModel user) => hasSkill(user, studiesManage);
  bool canManageFinancial(UserModel user) => hasSkill(user, financialManage);
  bool canManageBazaar(UserModel user) => hasSkill(user, bazaarManage);
  bool canManageCleaning(UserModel user) => hasSkill(user, cleaningManage);
  bool canModerateEntities(UserModel user) => hasSkill(user, entitiesModerate);
  bool canSendNotifications(UserModel user) =>
      hasSkill(user, notificationsNotify);

  /// Admin ou membro com ao menos uma skill de gestão: vê o painel administrativo.
  bool canAccessAdminHub(UserModel user) =>
      isAdmin(user) || allSkills.any((skill) => hasSkill(user, skill));

  /// Gestão de membros, papéis, atalhos da Home e aprovação de comprovantes
  /// continuam só do admin (não existe skill para isso).
  bool canManageMembers(UserModel user) => isAdmin(user);

  bool isVisitor(UserModel user) => user.role == 'visitor';
  bool isUser(UserModel user) => user.role == 'user';
  bool isAdmin(UserModel user) => user.role == 'admin';

  /// Membro = 'user' ou 'admin': acessa mural, estudos, financeiro e afins.
  bool isMember(UserModel user) => isUser(user) || isAdmin(user);
}
