import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/admin/domain/member_tabs.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

UserModel user(String name, String role, {String status = 'active', String? email}) => UserModel(
  id: name, name: name, email: email ?? '${name.toLowerCase()}@x.com', phone: '1',
  emergencyContact: '1', tenantSlug: 'tucttx', jaTirouSanto: false, role: role, status: status,
);

void main() {
  final all = [
    user('Ana', 'admin'),
    user('Bia', 'user'),
    user('Caio', 'user'),
    user('Davi', 'visitor'),
    user('Eva', 'visitor', status: 'pending_approval'),
    user('Zeca', 'admin'),
  ];
  List<String> names(MemberTab t, {String q = ''}) => usersForTab(all, t, query: q).map((u) => u.name).toList();

  test('visitantes: só visitantes, quem pediu acesso primeiro', () {
    expect(names(MemberTab.visitors), ['Eva', 'Davi']);
  });

  test('membros: filhos de santo E admins', () {
    expect(names(MemberTab.members), ['Ana', 'Bia', 'Caio', 'Zeca']);
  });

  test('admins: só administradores', () {
    expect(names(MemberTab.admins), ['Ana', 'Zeca']);
  });

  test('um admin aparece em "membros" e em "admins", nunca em "visitantes"', () {
    final ana = all.first;
    expect(MemberTab.members.includes(ana), isTrue);
    expect(MemberTab.admins.includes(ana), isTrue);
    expect(MemberTab.visitors.includes(ana), isFalse);
  });

  test('visitante nunca aparece em membros nem em admins', () {
    final davi = all[3];
    expect(MemberTab.members.includes(davi), isFalse);
    expect(MemberTab.admins.includes(davi), isFalse);
  });

  test('todo mundo cai em pelo menos uma aba', () {
    for (final u in all) {
      expect(MemberTab.values.any((t) => t.includes(u)), isTrue, reason: u.name);
    }
  });

  test('busca por nome ou e-mail, sem diferenciar maiúsculas, dentro da aba', () {
    expect(names(MemberTab.members, q: 'BIA'), ['Bia']);
    expect(names(MemberTab.members, q: 'caio@x'), ['Caio']);
    expect(names(MemberTab.admins, q: 'bia'), isEmpty); // Bia não é admin
    expect(names(MemberTab.visitors, q: '  eva '), ['Eva']);
  });

  test('ordem por nome ignora maiúsculas', () {
    final mixed = [user('beto', 'user'), user('Ana', 'user'), user('carla', 'user')];
    expect(usersForTab(mixed, MemberTab.members).map((u) => u.name), ['Ana', 'beto', 'carla']);
  });

  test('lista vazia', () {
    expect(usersForTab([], MemberTab.members), isEmpty);
  });
}
