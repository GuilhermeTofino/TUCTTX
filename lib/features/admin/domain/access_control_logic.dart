/// Lógica pura de mudança de acesso (papel, status, skills) e do "desfazer".
/// Sem Firebase, para ser testável. A transação fica no repositório.
library;

/// Uma linha do audit_log a gravar. `action`: role_change | skill_grant | skill_revoke.
class AuditDraft {
  final String action;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  const AuditDraft(this.action, this.before, this.after);
}

const _accessKeys = ['role', 'status', 'skills'];

bool _sameSkills(Object? a, Object? b) {
  final x = List<String>.from((a as List?) ?? const [])..sort();
  final y = List<String>.from((b as List?) ?? const [])..sort();
  if (x.length != y.length) return false;
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return false;
  }
  return true;
}

bool _sameValue(String key, Object? a, Object? b) =>
    key == 'skills' ? _sameSkills(a, b) : a == b;

/// Estado de acesso atual do usuário, com os padrões dos documentos antigos.
Map<String, dynamic> accessState(Map<String, dynamic> userDoc) => {
  'role': userDoc['role'] ?? 'visitor',
  'status': userDoc['status'] ?? 'active',
  'skills': List<String>.from((userDoc['skills'] as List?) ?? const []),
};

/// Planeja o que gravar no audit_log para levar [current] até [changes]
/// (subconjunto de role/status/skills). Vazio se nada muda de fato.
///
/// - Mudou papel ou status: uma entrada `role_change` (se as skills também mudam,
///   como ao rebaixar para consulente, entram na mesma entrada).
/// - Mudaram só as skills: uma entrada `skill_grant` (acrescentadas) e/ou uma
///   `skill_revoke` (retiradas), encadeadas (o "depois" de uma é o "antes" da outra),
///   para cada uma poder ser desfeita na ordem inversa.
List<AuditDraft> planAccessChange({
  required Map<String, dynamic> current,
  required Map<String, dynamic> changes,
}) {
  final unknown = changes.keys.where((k) => !_accessKeys.contains(k));
  if (unknown.isNotEmpty) {
    throw ArgumentError('Campos de acesso inválidos: ${unknown.join(', ')}');
  }

  final changed = <String>[
    for (final k in _accessKeys)
      if (changes.containsKey(k) && !_sameValue(k, current[k], changes[k])) k,
  ];
  if (changed.isEmpty) return const [];

  final roleOrStatus = changed.where((k) => k != 'skills').isNotEmpty;
  if (roleOrStatus) {
    return [
      AuditDraft(
        'role_change',
        {for (final k in changed) k: current[k]},
        {for (final k in changed) k: changes[k]},
      ),
    ];
  }

  final now = List<String>.from(current['skills'] as List);
  final target = List<String>.from(changes['skills'] as List);
  final added = target.where((s) => !now.contains(s)).toList();
  final removed = now.where((s) => !target.contains(s)).toList();

  final drafts = <AuditDraft>[];
  var state = now;
  if (added.isNotEmpty) {
    final next = [...state, ...added];
    drafts.add(AuditDraft('skill_grant', {'skills': state}, {'skills': next}));
    state = next;
  }
  if (removed.isNotEmpty) {
    final next = state.where((s) => !removed.contains(s)).toList();
    drafts.add(AuditDraft('skill_revoke', {'skills': state}, {'skills': next}));
  }
  return drafts;
}

/// Motivo pelo qual NÃO dá para desfazer, ou null se pode.
/// Só desfaz se o usuário ainda está exatamente no estado que a ação deixou
/// (`after`); senão, reaplicar o "antes" apagaria mudanças feitas depois.
String? undoBlockedReason({
  required Map<String, dynamic> currentUser,
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
  required bool alreadyUndone,
}) {
  if (alreadyUndone) return 'Esta ação já foi desfeita.';
  if (before.isEmpty) return 'Registro sem estado anterior.';
  final state = accessState(currentUser);
  for (final key in after.keys) {
    if (!_accessKeys.contains(key)) continue;
    if (!_sameValue(key, state[key], after[key])) {
      return 'O acesso deste membro mudou depois desta ação; desfaça as mais recentes primeiro.';
    }
  }
  return null;
}
