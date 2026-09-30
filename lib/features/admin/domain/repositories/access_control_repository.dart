import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';
import 'package:app_tenda/core/services/permission_service.dart';
import 'package:app_tenda/features/admin/domain/access_control_logic.dart';
import 'package:app_tenda/features/admin/domain/models/audit_log_entry.dart';

/// Mudanças de acesso (papel, status, skills) dos membros, com auditoria.
/// Cada mudança e seus registros de auditoria são gravados na MESMA transação.
abstract class AccessControlRepository {
  /// Aplica [changes] (subconjunto de role/status/skills) ao membro e grava o
  /// audit_log. Não faz nada se nada muda de fato.
  Future<void> applyAccessChange({
    required String targetUserId,
    required String actorId,
    required Map<String, dynamic> changes,
  });

  /// Desfaz uma entrada do log: reaplica o `before`, marca a entrada como
  /// desfeita e grava uma nova entrada para a reversão. Lança [StateError] com
  /// o motivo se o estado do membro mudou depois da ação.
  Future<void> undo({required String logId, required String actorId});

  /// Histórico do membro, do mais recente ao mais antigo (até 50).
  Future<List<AuditLogEntry>> getHistory(String userId);

  /// Catálogo de skills; se `skills_catalog` estiver vazio, os padrões do app.
  Future<List<SkillDefinition>> getSkillsCatalog();
}

class FirebaseAccessControlRepository extends BaseFirestoreDataSource
    implements AccessControlRepository {
  CollectionReference get _audit => tenantCollection('audit_log');

  @override
  Future<void> applyAccessChange({
    required String targetUserId,
    required String actorId,
    required Map<String, dynamic> changes,
  }) async {
    final userRef = tenantDocument('users', targetUserId);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) throw StateError('Membro não encontrado.');

      final current = accessState(snap.data() as Map<String, dynamic>);
      final drafts = planAccessChange(current: current, changes: changes);
      if (drafts.isEmpty) return;

      tx.update(userRef, {
        for (final key in changes.keys) key: changes[key],
      });
      for (final draft in drafts) {
        tx.set(_audit.doc(), {
          'targetUserId': targetUserId,
          'actorId': actorId,
          'action': draft.action,
          'before': draft.before,
          'after': draft.after,
          'timestamp': FieldValue.serverTimestamp(),
          'undone': false,
        });
      }
    });
  }

  @override
  Future<void> undo({required String logId, required String actorId}) async {
    final logRef = _audit.doc(logId);

    await firestore.runTransaction((tx) async {
      final logSnap = await tx.get(logRef);
      if (!logSnap.exists) throw StateError('Registro não encontrado.');
      final log = AuditLogEntry.fromMap(
        logSnap.data() as Map<String, dynamic>,
        logSnap.id,
      );

      final userRef = tenantDocument('users', log.targetUserId);
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw StateError('Membro não encontrado.');

      final blocked = undoBlockedReason(
        currentUser: userSnap.data() as Map<String, dynamic>,
        before: log.before,
        after: log.after,
        alreadyUndone: log.undone,
      );
      if (blocked != null) throw StateError(blocked);

      tx.update(userRef, log.before);
      tx.update(logRef, {'undone': true});
      tx.set(_audit.doc(), {
        'targetUserId': log.targetUserId,
        'actorId': actorId,
        'action': log.action,
        'undoOf': log.id,
        // A reversão troca "antes" e "depois".
        'before': log.after,
        'after': log.before,
        'timestamp': FieldValue.serverTimestamp(),
        'undone': false,
      });
    });
  }

  @override
  Future<List<AuditLogEntry>> getHistory(String userId) async {
    // Sem orderBy no servidor para não exigir índice composto; ordena aqui.
    final snapshot = await _audit.where('targetUserId', isEqualTo: userId).get();
    final entries = snapshot.docs
        .map((d) => AuditLogEntry.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList()
      ..sort((a, b) => (b.timestamp ?? DateTime.now())
          .compareTo(a.timestamp ?? DateTime.now()));
    return entries.take(50).toList();
  }

  @override
  Future<List<SkillDefinition>> getSkillsCatalog() async {
    final snapshot = await tenantCollection('skills_catalog').get();
    if (snapshot.docs.isEmpty) return _defaultCatalog;

    final fromCatalog = {
      for (final doc in snapshot.docs)
        doc.id: SkillDefinition(
          doc.id,
          (doc.data() as Map<String, dynamic>)['label'] ??
              PermissionService.skillLabels[doc.id] ??
              doc.id,
          (doc.data() as Map<String, dynamic>)['description'] ?? '',
        ),
    };
    // Só oferece skills que o app entende (as regras só conhecem essas).
    return [
      for (final key in PermissionService.allSkills)
        fromCatalog[key] ?? SkillDefinition(key, PermissionService.skillLabels[key] ?? key),
    ];
  }

  static final List<SkillDefinition> _defaultCatalog = [
    for (final key in PermissionService.allSkills)
      SkillDefinition(key, PermissionService.skillLabels[key] ?? key),
  ];
}
