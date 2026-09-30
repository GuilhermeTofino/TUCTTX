import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/admin/domain/access_control_logic.dart';

Map<String, dynamic> user({
  String role = 'user',
  String status = 'active',
  List<String> skills = const [],
}) => {'role': role, 'status': status, 'skills': skills};

void main() {
  group('accessState', () {
    test('documento antigo, sem status/skills, ganha os padrões', () {
      expect(accessState({'role': 'user'}), {
        'role': 'user',
        'status': 'active',
        'skills': <String>[],
      });
    });

    test('sem role vira visitante', () {
      expect(accessState({})['role'], 'visitor');
    });
  });

  group('planAccessChange', () {
    test('aprovar visitante pendente: uma entrada role_change com role e status', () {
      final drafts = planAccessChange(
        current: user(role: 'visitor', status: 'pending_approval'),
        changes: {'role': 'user', 'status': 'active'},
      );
      expect(drafts, hasLength(1));
      expect(drafts.single.action, 'role_change');
      expect(drafts.single.before, {'role': 'visitor', 'status': 'pending_approval'});
      expect(drafts.single.after, {'role': 'user', 'status': 'active'});
    });

    test('rebaixar para visitante leva as skills junto, na mesma entrada', () {
      final drafts = planAccessChange(
        current: user(skills: ['mural.publicar']),
        changes: {'role': 'visitor', 'status': 'active', 'skills': <String>[]},
      );
      expect(drafts, hasLength(1));
      expect(drafts.single.before, {'role': 'user', 'skills': ['mural.publicar']});
      expect(drafts.single.after, {'role': 'visitor', 'skills': <String>[]});
    });

    test('só acrescentar skills gera skill_grant', () {
      final drafts = planAccessChange(
        current: user(skills: ['a']),
        changes: {'skills': ['a', 'b']},
      );
      expect(drafts.map((d) => d.action), ['skill_grant']);
      expect(drafts.single.before, {'skills': ['a']});
      expect(drafts.single.after, {'skills': ['a', 'b']});
    });

    test('só retirar skills gera skill_revoke', () {
      final drafts = planAccessChange(
        current: user(skills: ['a', 'b']),
        changes: {'skills': ['a']},
      );
      expect(drafts.map((d) => d.action), ['skill_revoke']);
    });

    test('acrescentar e retirar ao mesmo tempo: duas entradas encadeadas', () {
      final drafts = planAccessChange(
        current: user(skills: ['a', 'b']),
        changes: {'skills': ['b', 'c']},
      );
      expect(drafts.map((d) => d.action), ['skill_grant', 'skill_revoke']);
      // o "depois" do grant é o "antes" do revoke
      expect(drafts[0].after, drafts[1].before);
      expect(drafts[0].after, {'skills': ['a', 'b', 'c']});
      expect(drafts[1].after, {'skills': ['b', 'c']});
    });

    test('nada muda: não gera registro (ordem das skills não conta)', () {
      expect(
        planAccessChange(current: user(skills: ['a', 'b']), changes: {'skills': ['b', 'a']}),
        isEmpty,
      );
      expect(
        planAccessChange(current: user(), changes: {'role': 'user', 'status': 'active'}),
        isEmpty,
      );
    });

    test('só registra o que mudou de fato', () {
      final drafts = planAccessChange(
        current: user(role: 'visitor'),
        changes: {'role': 'user', 'status': 'active'}, // status já era 'active'
      );
      expect(drafts.single.before, {'role': 'visitor'});
      expect(drafts.single.after, {'role': 'user'});
    });

    test('rejeita campo que não é de acesso', () {
      expect(
        () => planAccessChange(current: user(), changes: {'name': 'x'}),
        throwsArgumentError,
      );
    });
  });

  group('undoBlockedReason', () {
    test('estado ainda é o que a ação deixou: pode desfazer', () {
      expect(
        undoBlockedReason(
          currentUser: user(role: 'user', status: 'active'),
          before: {'role': 'visitor', 'status': 'pending_approval'},
          after: {'role': 'user', 'status': 'active'},
          alreadyUndone: false,
        ),
        isNull,
      );
    });

    test('já desfeito', () {
      expect(
        undoBlockedReason(
          currentUser: user(),
          before: {'role': 'visitor'},
          after: {'role': 'user'},
          alreadyUndone: true,
        ),
        contains('já foi desfeita'),
      );
    });

    test('o acesso mudou depois: desfazer apagaria a mudança mais nova', () {
      // ação antiga: visitor -> user; depois virou admin
      expect(
        undoBlockedReason(
          currentUser: user(role: 'admin'),
          before: {'role': 'visitor'},
          after: {'role': 'user'},
          alreadyUndone: false,
        ),
        contains('mudou depois'),
      );
    });

    test('skills: compara sem depender da ordem', () {
      expect(
        undoBlockedReason(
          currentUser: user(skills: ['b', 'a']),
          before: {'skills': ['a']},
          after: {'skills': ['a', 'b']},
          alreadyUndone: false,
        ),
        isNull,
      );
      expect(
        undoBlockedReason(
          currentUser: user(skills: ['a', 'b', 'c']),
          before: {'skills': ['a']},
          after: {'skills': ['a', 'b']},
          alreadyUndone: false,
        ),
        isNotNull,
      );
    });

    test('registro sem estado anterior não desfaz', () {
      expect(
        undoBlockedReason(
          currentUser: user(),
          before: {},
          after: {'role': 'user'},
          alreadyUndone: false,
        ),
        isNotNull,
      );
    });

    test('desfazer em cadeia só funciona na ordem inversa', () {
      final drafts = planAccessChange(
        current: user(skills: ['a', 'b']),
        changes: {'skills': ['b', 'c']},
      );
      final grant = drafts[0], revoke = drafts[1];
      final finalUser = user(skills: ['b', 'c']);
      // desfazer o grant primeiro (o revoke veio depois): bloqueado
      expect(
        undoBlockedReason(currentUser: finalUser, before: grant.before, after: grant.after, alreadyUndone: false),
        isNotNull,
      );
      // desfazer o revoke primeiro: liberado
      expect(
        undoBlockedReason(currentUser: finalUser, before: revoke.before, after: revoke.after, alreadyUndone: false),
        isNull,
      );
    });
  });
}
