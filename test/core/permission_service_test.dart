import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/core/services/permission_service.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

UserModel user(String role, {List<String> skills = const []}) => UserModel(
  id: 'u',
  name: 'N',
  email: 'e@e.com',
  phone: '1',
  emergencyContact: '1',
  tenantSlug: 'tucttx',
  jaTirouSanto: false,
  role: role,
  skills: skills,
);

void main() {
  final service = PermissionService();

  test('admin tem todas as skills', () {
    for (final skill in PermissionService.allSkills) {
      expect(service.hasSkill(user('admin'), skill), isTrue, reason: skill);
    }
  });

  test('membro só tem as skills da própria lista', () {
    final u = user('user', skills: [PermissionService.bulletinPost]);
    expect(service.canPostBulletin(u), isTrue);
    expect(service.canManageFinancial(u), isFalse);
    expect(service.canManageCalendar(u), isFalse);
  });

  test('consulente nunca tem skill, nem "no papel"', () {
    final u = user('visitor', skills: [PermissionService.bulletinPost]);
    for (final skill in PermissionService.allSkills) {
      expect(service.hasSkill(u, skill), isFalse, reason: skill);
    }
  });

  test('painel administrativo: admin ou membro com alguma skill', () {
    expect(service.canAccessAdminHub(user('admin')), isTrue);
    expect(service.canAccessAdminHub(user('user', skills: ['estudos.gerenciar'])), isTrue);
    expect(service.canAccessAdminHub(user('user')), isFalse);
    expect(service.canAccessAdminHub(user('visitor')), isFalse);
  });

  test('skill desconhecida no perfil não abre o painel', () {
    expect(service.canAccessAdminHub(user('user', skills: ['qualquer.coisa'])), isFalse);
  });

  test('gestão de membros é só do admin, mesmo com todas as skills', () {
    expect(service.canManageMembers(user('admin')), isTrue);
    expect(service.canManageMembers(user('user', skills: PermissionService.allSkills)), isFalse);
  });

  test('membro = user ou admin', () {
    expect(service.isMember(user('user')), isTrue);
    expect(service.isMember(user('admin')), isTrue);
    expect(service.isMember(user('visitor')), isFalse);
  });

  test('toda skill tem rótulo', () {
    for (final skill in PermissionService.allSkills) {
      expect(PermissionService.skillLabels[skill], isNotNull, reason: skill);
    }
  });

  test('as skills do app são as mesmas que as regras conhecem', () {
    // firestore.rules/storage.rules usam estas 8 chaves; se mudar aqui, mude lá.
    expect(PermissionService.allSkills.toSet(), {
      'calendario.gerenciar',
      'mural.publicar',
      'estudos.gerenciar',
      'financeiro.gerenciar',
      'bazar.gerenciar',
      'limpeza.gerenciar',
      'entidades.moderar',
      'notificacoes.enviar',
    });
  });
}
