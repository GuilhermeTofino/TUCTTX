import 'package:flutter/material.dart';
import 'package:app_tenda/features/admin/domain/models/audit_log_entry.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

/// Checklist de skills de um membro. Devolve a lista marcada, ou null se cancelar.
Future<List<String>?> showSkillsDialog(
  BuildContext context, {
  required UserModel member,
  required List<SkillDefinition> catalog,
}) {
  final selected = {...member.skills};

  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Permissões de ${member.name.split(' ').first}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final skill in catalog)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(skill.key),
                  title: Text(skill.label),
                  subtitle: skill.description.isEmpty ? null : Text(skill.description),
                  onChanged: (checked) => setState(() {
                    checked == true ? selected.add(skill.key) : selected.remove(skill.key);
                  }),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            // Mantém a ordem do catálogo, para o histórico ficar previsível.
            onPressed: () => Navigator.pop(ctx, [
              for (final skill in catalog)
                if (selected.contains(skill.key)) skill.key,
            ]),
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}
