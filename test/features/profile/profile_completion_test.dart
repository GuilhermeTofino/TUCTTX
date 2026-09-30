import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/profile/domain/profile_completion.dart';

UserModel user(String role, {String emergency = ''}) => UserModel(
  id: 'u', name: 'N', email: 'e@e.com', phone: '1', emergencyContact: emergency,
  tenantSlug: 'tucttx', jaTirouSanto: false, role: role,
);

void main() {
  test('membro aprovado sem contato de emergência precisa completar', () {
    expect(needsProfileCompletion(user('user')), isTrue);
    expect(needsProfileCompletion(user('admin')), isTrue);
    expect(needsProfileCompletion(user('user', emergency: '   ')), isTrue);
  });

  test('membro com contato de emergência está completo', () {
    expect(needsProfileCompletion(user('user', emergency: 'Mãe 11988887777')), isFalse);
  });

  test('consulente nunca é cobrado, mesmo sem contato', () {
    expect(needsProfileCompletion(user('visitor')), isFalse);
  });
}
