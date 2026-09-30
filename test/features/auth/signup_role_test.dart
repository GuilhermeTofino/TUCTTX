import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/auth/domain/signup_role.dart';

void main() {
  test('interruptor desligado: cadastro segue entrando como membro (como hoje)', () {
    expect(signupRoleFor(visitorSignupEnabled: false), 'user');
  });

  test('interruptor ligado: cadastro entra como visitante', () {
    expect(signupRoleFor(visitorSignupEnabled: true), 'visitor');
  });
}
