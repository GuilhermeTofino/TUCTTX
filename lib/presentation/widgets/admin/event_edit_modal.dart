import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/domain/models/work_event_model.dart';

class EventEditModal extends StatefulWidget {
  final WorkEvent event;
  final Function(Map<String, dynamic> updatedData) onSave;
  final VoidCallback onDelete;

  const EventEditModal({
    super.key,
    required this.event,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EventEditModal> createState() => _EventEditModalState();
}

class _EventEditModalState extends State<EventEditModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedType;
  late List<String> _cleaningCrew;

  final List<String> _eventTypes = [
    "Pública",
    "Interna",
    "Trabalho",
    "Desenvolvimento",
    "Outro",
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description ?? "",
    );
    _selectedDate = widget.event.date;
    _selectedType = widget.event.type.trim(); // Garante sem espaços extras
    _cleaningCrew = List.from(widget.event.cleaningCrew ?? []);

    // Garante que o tipo atual está na lista e que não há duplicatas
    if (!_eventTypes.contains(_selectedType)) {
      _eventTypes.add(_selectedType);
    }

    // Limpeza final: remove nulos, vazios e duplicatas acidentais
    final uniqueTypes = _eventTypes.where((t) => t.isNotEmpty).toSet().toList();
    _eventTypes.clear();
    _eventTypes.addAll(uniqueTypes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addCrewMember() {
    showDialog(
      context: context,
      builder: (context) {
        String newMember = "";
        return AlertDialog(
          title: const Text("Adicionar à Faxina"),
          content: TextField(
            onChanged: (v) => newMember = v,
            decoration: const InputDecoration(hintText: "Nome do filho"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                if (newMember.isNotEmpty) {
                  setState(() => _cleaningCrew.add(newMember.trim()));
                  Navigator.pop(context);
                }
              },
              child: const Text("Adicionar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Editar Gira",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Excluir Gira?"),
                        content: const Text("Esta ação não pode ser desfeita."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Não"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onDelete();
                            },
                            child: const Text(
                              "Sim, Excluir",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Título da Gira"),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Data e Hora"),
              subtitle: Text(
                DateFormat("dd/MM/yyyy 'às' HH:mm").format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _eventTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: "Tipo"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descrição/Observações",
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Equipe de Faxina",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addCrewMember,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Adicionar"),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _cleaningCrew.map((name) {
                return Chip(
                  label: Text(name),
                  onDeleted: () => setState(() => _cleaningCrew.remove(name)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final data = {
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'date': _selectedDate.toIso8601String(),
                    'type': _selectedType,
                    'cleaningCrew': _cleaningCrew,
                  };
                  widget.onSave(data);
                },
                child: const Text("Salvar Alterações"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
