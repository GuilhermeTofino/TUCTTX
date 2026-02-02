import 'package:flutter/material.dart';
import '../../../domain/models/menu_option_model.dart';
import 'package:uuid/uuid.dart';

class MenuEditModal extends StatefulWidget {
  final MenuOptionModel? menu;
  final Function(MenuOptionModel) onSave;

  const MenuEditModal({super.key, this.menu, required this.onSave});

  @override
  State<MenuEditModal> createState() => _MenuEditModalState();
}

class _MenuEditModalState extends State<MenuEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _orderController;

  String _selectedIcon = 'help_outline';
  String _selectedColor = '#2196F3';
  String _selectedAction = 'internal:coming_soon';

  final List<Map<String, dynamic>> _availableIcons = [
    {
      'name': 'Calendário',
      'key': 'calendar',
      'icon': Icons.calendar_today_outlined,
    },
    {
      'name': 'Financeiro',
      'key': 'finance',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'name': 'Saúde',
      'key': 'health',
      'icon': Icons.health_and_safety_outlined,
    },
    {
      'name': 'Documentos',
      'key': 'documents',
      'icon': Icons.description_outlined,
    },
    {'name': 'Ajuda', 'key': 'help_outline', 'icon': Icons.help_outline},
  ];

  final List<Map<String, dynamic>> _availableActions = [
    {'name': 'Abrir Calendário', 'key': 'route:/calendar'},
    {'name': 'Dados de Saúde', 'key': 'internal:health'},
    {'name': 'Em Breve (Aviso)', 'key': 'internal:coming_soon'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.menu?.title ?? '');
    _orderController = TextEditingController(
      text: (widget.menu?.order ?? 0).toString(),
    );

    if (widget.menu != null) {
      _selectedIcon = widget.menu!.icon;
      _selectedColor = widget.menu!.color;
      _selectedAction = widget.menu!.action;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Blindagem: Garante que os valores selecionados existem nas listas atuais
    // Se não existirem (ex: dados antigos ou erro de sync), volta para o padrão seguro.
    final String currentIcon =
        _availableIcons.any((i) => i['key'] == _selectedIcon)
        ? _selectedIcon
        : 'help_outline';

    final String currentAction =
        _availableActions.any((a) => a['key'] == _selectedAction)
        ? _selectedAction
        : 'internal:coming_soon';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.menu == null ? "Novo Item de Menu" : "Editar Item",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Título Display",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? "Obrigatório" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: currentIcon,
                decoration: const InputDecoration(
                  labelText: "Ícone",
                  border: OutlineInputBorder(),
                ),
                items: _availableIcons
                    .map(
                      (i) => DropdownMenuItem<String>(
                        value: i['key'],
                        child: Row(
                          children: [
                            Icon(i['icon'], size: 20),
                            const SizedBox(width: 8),
                            Text(i['name']),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedIcon = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: currentAction,
                decoration: const InputDecoration(
                  labelText: "Ação ao Clicar",
                  border: OutlineInputBorder(),
                ),
                items: _availableActions
                    .map(
                      (a) => DropdownMenuItem<String>(
                        value: a['key'],
                        child: Text(a['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAction = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: "Ordem (Ex: 0, 1, 2)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final menu = MenuOptionModel(
                        id: widget.menu?.id ?? const Uuid().v4(),
                        title: _titleController.text,
                        icon: _selectedIcon,
                        color: _selectedColor,
                        action: _selectedAction,
                        order: int.tryParse(_orderController.text) ?? 999,
                        isEnabled: true,
                      );
                      widget.onSave(menu);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Salvar Alterações"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
