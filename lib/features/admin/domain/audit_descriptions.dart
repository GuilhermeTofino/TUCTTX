import 'package:app_tenda/core/services/permission_service.dart';
import 'package:app_tenda/features/admin/domain/models/audit_log_entry.dart';

/// Texto em português de uma entrada do histórico de acesso.
/// Ex.: "Papel: Consulente → Filho(a) de santo · Status: Aguardando aprovação → Ativo".
String describeAuditEntry(AuditLogEntry entry) {
  final body = switch (entry.action) {
    'skill_grant' => _skillsDiff(entry, granted: true),
    'skill_revoke' => _skillsDiff(entry, granted: false),
    _ => _roleChange(entry),
  };
  return entry.undoOf != null ? 'Reversão · $body' : body;
}

const _roles = {
  'visitor': 'Consulente',
  'user': 'Filho(a) de santo',
  'admin': 'Administrador',
};
const _statuses = {'active': 'Ativo', 'pending_approval': 'Aguardando aprovação'};

String _roleChange(AuditLogEntry entry) {
  final parts = <String>[];
  for (final key in ['role', 'status', 'skills']) {
    if (!entry.after.containsKey(key)) continue;
    switch (key) {
      case 'role':
        parts.add('Papel: ${_roles[entry.before['role']] ?? entry.before['role']} → ${_roles[entry.after['role']] ?? entry.after['role']}');
      case 'status':
        parts.add('Status: ${_statuses[entry.before['status']] ?? entry.before['status']} → ${_statuses[entry.after['status']] ?? entry.after['status']}');
      case 'skills':
        final before = _skillList(entry.before['skills']);
        final after = _skillList(entry.after['skills']);
        parts.add(after.isEmpty ? 'Permissões removidas' : 'Permissões: ${before.isEmpty ? 'nenhuma' : before.join(', ')} → ${after.join(', ')}');
    }
  }
  return parts.isEmpty ? 'Alteração de acesso' : parts.join(' · ');
}

String _skillsDiff(AuditLogEntry entry, {required bool granted}) {
  final before = List<String>.from((entry.before['skills'] as List?) ?? const []);
  final after = List<String>.from((entry.after['skills'] as List?) ?? const []);
  final changed = granted
      ? after.where((s) => !before.contains(s))
      : before.where((s) => !after.contains(s));
  final names = _skillList(changed.toList());
  final label = granted ? 'Permissões concedidas' : 'Permissões retiradas';
  return names.isEmpty ? label : '$label: ${names.join(', ')}';
}

List<String> _skillList(Object? skills) => [
  for (final key in (skills as List? ?? const []))
    PermissionService.skillLabels[key] ?? key.toString(),
];
