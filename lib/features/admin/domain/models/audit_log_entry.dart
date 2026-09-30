import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de mudança de acesso (papel/status/skills) de um membro.
class AuditLogEntry {
  final String id;
  final String targetUserId;
  final String actorId;
  final String action; // role_change | skill_grant | skill_revoke
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final DateTime? timestamp;
  final bool undone;
  final String? undoOf;

  const AuditLogEntry({
    required this.id,
    required this.targetUserId,
    required this.actorId,
    required this.action,
    required this.before,
    required this.after,
    required this.undone,
    this.timestamp,
    this.undoOf,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogEntry(
      id: id,
      targetUserId: map['targetUserId'] ?? '',
      actorId: map['actorId'] ?? '',
      action: map['action'] ?? 'role_change',
      before: Map<String, dynamic>.from(map['before'] ?? const {}),
      after: Map<String, dynamic>.from(map['after'] ?? const {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      undone: map['undone'] ?? false,
      undoOf: map['undoOf'],
    );
  }
}

/// Skill do catálogo (`skills_catalog`), com rótulo para a tela do admin.
class SkillDefinition {
  final String key;
  final String label;
  final String description;
  const SkillDefinition(this.key, this.label, [this.description = '']);
}
