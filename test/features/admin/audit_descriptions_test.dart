import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/features/admin/domain/audit_descriptions.dart';
import 'package:app_tenda/features/admin/domain/models/audit_log_entry.dart';

AuditLogEntry entry(
  String action,
  Map<String, dynamic> before,
  Map<String, dynamic> after, {
  String? undoOf,
}) => AuditLogEntry(
  id: 'l',
  targetUserId: 'u',
  actorId: 'a',
  action: action,
  before: before,
  after: after,
  undone: false,
  undoOf: undoOf,
);

void main() {
  test('aprovação de consulente', () {
    expect(
      describeAuditEntry(entry('role_change',
        {'role': 'visitor', 'status': 'pending_approval'},
        {'role': 'user', 'status': 'active'})),
      'Papel: Consulente → Filho(a) de santo · Status: Aguardando aprovação → Ativo',
    );
  });

  test('rebaixar para consulente mostra que as permissões foram removidas', () {
    expect(
      describeAuditEntry(entry('role_change',
        {'role': 'user', 'skills': ['mural.publicar']},
        {'role': 'visitor', 'skills': <String>[]})),
      'Papel: Filho(a) de santo → Consulente · Permissões removidas',
    );
  });

  test('skills concedidas e retiradas usam os rótulos', () {
    expect(
      describeAuditEntry(entry('skill_grant', {'skills': ['a']}, {'skills': ['a', 'mural.publicar']})),
      'Permissões concedidas: Publicar no mural',
    );
    expect(
      describeAuditEntry(entry('skill_revoke', {'skills': ['financeiro.gerenciar', 'bazar.gerenciar']}, {'skills': ['bazar.gerenciar']})),
      'Permissões retiradas: Gerenciar financeiro',
    );
  });

  test('reversão é sinalizada', () {
    expect(
      describeAuditEntry(entry('role_change', {'role': 'user'}, {'role': 'visitor'}, undoOf: 'x')),
      startsWith('Reversão · '),
    );
  });

  test('valores desconhecidos aparecem como estão, sem quebrar', () {
    expect(
      describeAuditEntry(entry('role_change', {'role': 'x'}, {'role': 'y'})),
      'Papel: x → y',
    );
    expect(describeAuditEntry(entry('role_change', {}, {})), 'Alteração de acesso');
  });
}
