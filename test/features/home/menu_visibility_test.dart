import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/core/services/menu_option_model.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/home/domain/menu_visibility.dart';

UserModel user(String role) => UserModel(
  id: 'u', name: 'N', email: 'e@e.com', phone: '1', emergencyContact: '1',
  tenantSlug: 'tucttx', jaTirouSanto: false, role: role,
);

MenuOptionModel menu(String action) => MenuOptionModel(
  id: action, title: action, icon: 'x', color: '#000000', action: action, order: 1,
);

void main() {
  final all = [
    menu('route:/calendar'),
    menu('internal:finance'),
    menu('internal:studies'),
    menu('route:/cambone-list'),
    menu('route:/admin-house-entities'),
  ];

  test('visitante só vê o calendário', () {
    expect(menusFor(user('visitor'), all).map((m) => m.action), ['route:/calendar']);
  });

  test('membro e admin veem todos', () {
    expect(menusFor(user('user'), all), hasLength(5));
    expect(menusFor(user('admin'), all), hasLength(5));
  });

  test('sem menu de calendário, o visitante não vê nada', () {
    expect(menusFor(user('visitor'), [menu('internal:finance')]), isEmpty);
  });

  test('não altera a lista original', () {
    menusFor(user('visitor'), all);
    expect(all, hasLength(5));
  });
}
