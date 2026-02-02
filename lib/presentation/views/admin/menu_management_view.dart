import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/models/menu_option_model.dart';
import '../../../domain/repositories/menu_repository.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/admin/menu_edit_modal.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  final HomeViewModel _viewModel = getIt<HomeViewModel>();
  final MenuRepository _menuRepository = getIt<MenuRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Gerenciar Atalhos",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final menus = _viewModel.menus;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    menu.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Ordem: ${menu.order} | ${menu.action}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                        ),
                        onPressed: () => _openEditModal(menu: menu),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDelete(menu.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditModal(),
        backgroundColor: Colors.black,
        label: const Text("Novo Atalho", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openEditModal({MenuOptionModel? menu}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuEditModal(
        menu: menu,
        onSave: (updatedMenu) async {
          await _menuRepository.saveMenu(updatedMenu);
          await _viewModel.loadMenus(_viewModel.currentUser!.tenantSlug);
        },
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir item?"),
        content: const Text(
          "Essa ação é permanente e afetará todos os usuários.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await _menuRepository.deleteMenu(id);
              await _viewModel.loadMenus(_viewModel.currentUser!.tenantSlug);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
