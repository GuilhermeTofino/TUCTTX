import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/profile/domain/profile_validation.dart';
import 'package:app_tenda/features/profile/domain/models/health_data_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';

void main() {
  group('nome', () {
    test('vazio e curto são recusados', () {
      expect(ProfileValidation.name(null), isNotNull);
      expect(ProfileValidation.name('   '), isNotNull);
      expect(ProfileValidation.name('A'), isNotNull);
    });
    test('aceita nome normal, ignorando espaços nas pontas', () {
      expect(ProfileValidation.name('  Ana Souza '), isNull);
    });
  });

  group('telefone', () {
    test('aceita 10 ou 11 dígitos, com ou sem máscara', () {
      expect(ProfileValidation.phone('(11) 98888-7777'), isNull);
      expect(ProfileValidation.phone('1133334444'), isNull);
    });
    test('recusa vazio, curto e longo demais', () {
      expect(ProfileValidation.phone(''), isNotNull);
      expect(ProfileValidation.phone('12345'), isNotNull);
      expect(ProfileValidation.phone('123456789012'), isNotNull);
    });
  });

  group('data de nascimento', () {
    final now = DateTime(2026, 9, 30);
    test('é opcional', () => expect(ProfileValidation.birthDate(null, now: now), isNull));
    test('aceita data passada', () => expect(ProfileValidation.birthDate(DateTime(1990, 5, 1), now: now), isNull));
    test('recusa futura e antes de 1900', () {
      expect(ProfileValidation.birthDate(DateTime(2027, 1, 1), now: now), isNotNull);
      expect(ProfileValidation.birthDate(DateTime(1850, 1, 1), now: now), isNotNull);
    });
    test('hoje é aceito', () => expect(ProfileValidation.birthDate(now, now: now), isNull));
  });

  group('campo obrigatório', () {
    test('vazio ou só espaços é recusado, com a mensagem pedida', () {
      expect(ProfileValidation.required(null, 'falta'), 'falta');
      expect(ProfileValidation.required('   ', 'falta'), 'falta');
    });
    test('texto livre é aceito (contato pode ter nome e número)', () {
      expect(ProfileValidation.required('Mãe (11) 98888-7777', 'falta'), isNull);
    });
  });

  test('campo opcional em branco vira null', () {
    expect(ProfileValidation.optional('   '), isNull);
    expect(ProfileValidation.optional(null), isNull);
    expect(ProfileValidation.optional(' O+ '), 'O+');
  });

  group('HealthData', () {
    test('isEmpty ignora espaços', () {
      expect(const HealthData(alergias: '  ', tipoSanguineo: '').isEmpty, isTrue);
      expect(const HealthData(alergias: 'amendoim').isEmpty, isFalse);
    });
    test('toMap não grava texto em branco', () {
      final map = const HealthData(alergias: ' amendoim ', medicamentos: '   ').toMap();
      expect(map['alergias'], 'amendoim');
      expect(map['medicamentos'], isNull);
    });
    test('fromMap lê os quatro campos', () {
      final h = HealthData.fromMap({'alergias': 'a', 'medicamentos': 'm', 'condicoesMedicas': 'c', 'tipoSanguineo': 'O+'});
      expect([h.alergias, h.medicamentos, h.condicoesMedicas, h.tipoSanguineo], ['a', 'm', 'c', 'O+']);
    });
  });

  group('campos que o próprio usuário pode editar', () {
    test('inclui o que o membro completa depois de aprovado', () {
      expect(UserRepository.personalFields,
          containsAll(['name', 'phone', 'photoUrl', 'emergencyContact', 'jaTirouSanto', 'jogoComTata']));
    });
    test('NUNCA inclui acesso nem dados que só o sistema grava', () {
      for (final blocked in ['role', 'status', 'skills', 'fcmTokens', 'email', 'tenantSlug', 'createdAt', 'id']) {
        expect(UserRepository.personalFields.contains(blocked), isFalse, reason: blocked);
      }
    });
  });
}
