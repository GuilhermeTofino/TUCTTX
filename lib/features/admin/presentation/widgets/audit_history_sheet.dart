import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/features/admin/domain/audit_descriptions.dart';
import 'package:app_tenda/features/admin/domain/models/audit_log_entry.dart';
import 'package:app_tenda/features/admin/presentation/viewmodels/member_management_viewmodel.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

/// Histórico de mudanças de acesso de um membro, com "Desfazer" em cada entrada.
Future<void> showAuditHistorySheet(
  BuildContext context, {
  required UserModel member,
  required MemberManagementViewModel viewModel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AuditHistorySheet(member: member, viewModel: viewModel),
  );
}

class _AuditHistorySheet extends StatefulWidget {
  final UserModel member;
  final MemberManagementViewModel viewModel;
  const _AuditHistorySheet({required this.member, required this.viewModel});

  @override
  State<_AuditHistorySheet> createState() => _AuditHistorySheetState();
}

class _AuditHistorySheetState extends State<_AuditHistorySheet> {
  late Future<List<AuditLogEntry>> _future = _load();
  String? _busyId;

  Future<List<AuditLogEntry>> _load() => widget.viewModel.loadHistory(widget.member.id);

  Future<void> _undo(AuditLogEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = entry.id);
    try {
      await widget.viewModel.undo(entry);
      messenger.showSnackBar(const SnackBar(content: Text('Ação desfeita.')));
      setState(() => _future = _load());
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível desfazer. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('dd/MM/yyyy HH:mm');
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Histórico de ${widget.member.name.split(' ').first}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<AuditLogEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Não foi possível carregar o histórico.'));
                  }
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return const Center(child: Text('Nenhuma alteração registrada.'));
                  }
                  return ListView.separated(
                    controller: scroll,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final canUndo = !e.undone && e.undoOf == null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          describeAuditEntry(e),
                          style: TextStyle(
                            decoration: e.undone ? TextDecoration.lineThrough : null,
                            color: e.undone ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          e.timestamp == null ? '' : when.format(e.timestamp!.toLocal()),
                        ),
                        trailing: _busyId == e.id
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : canUndo
                                ? TextButton(onPressed: () => _undo(e), child: const Text('Desfazer'))
                                : (e.undone ? const Text('Desfeito', style: TextStyle(color: Colors.grey)) : null),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
