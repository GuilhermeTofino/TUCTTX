import 'package:app_tenda/features/auth/domain/models/user_model.dart';

class PermissionService {
  static const String calendarManage = 'calendario.gerenciar';
  static const String bulletinPost = 'mural.publicar';
  static const String studiesManage = 'estudos.gerenciar';
  static const String financialManage = 'financeiro.gerenciar';
  static const String bazaarManage = 'bazar.gerenciar';
  static const String cleaningManage = 'limpeza.gerenciar';
  static const String entitiesModerate = 'entidades.moderar';
  static const String notificationsNotify = 'notificacoes.enviar';

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
  bool canSendNotifications(UserModel user) => hasSkill(user, notificationsNotify);

  bool isVisitor(UserModel user) => user.role == 'visitor';
  bool isUser(UserModel user) => user.role == 'user';
  bool isAdmin(UserModel user) => user.role == 'admin';
}
