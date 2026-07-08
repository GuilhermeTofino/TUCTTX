import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../viewmodels/profile/my_entities_viewmodel.dart';
import '../../../../domain/models/entity_model.dart';
import '../../widgets/premium_sliver_app_bar.dart';

class MyEntitiesView extends StatelessWidget {
  const MyEntitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<MyEntitiesViewModel>(),
      child: const _MyEntitiesContent(),
    );
  }
}

class _MyEntitiesContent extends StatefulWidget {
  const _MyEntitiesContent();

  @override
  State<_MyEntitiesContent> createState() => _MyEntitiesContentState();
}

class _MyEntitiesContentState extends State<_MyEntitiesContent> {
  final TextEditingController _entityController = TextEditingController();
  String? _selectedType;

  final List<String> _entityTypes = [
    'Exu',
    'Pombagira',
    'Caboclo',
    'Preto Velho',
    'Erê',
    'Boiadeiro',
    'Malandro',
    'Baiano',
    'Marinheiro',
    'Outros',
  ];

  @override
  void dispose() {
    _entityController.dispose();
    super.dispose();
  }

  void _showAddEntityDialog(
    BuildContext context,
    MyEntitiesViewModel viewModel,
  ) {
    _selectedType = null;
    _entityController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Adicionar Entidade"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Tipo de Entidade",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _entityTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _entityController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                      hintText: "Ex: Tranca Ruas",
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("CANCELAR"),
                ),
                TextButton(
                  onPressed: () {
                    final name = _entityController.text.trim();
                    if (_selectedType != null && name.isNotEmpty) {
                      viewModel.addEntity(_selectedType!, name);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("ADICIONAR"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MyEntitiesViewModel>(context);
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(
            title: "Minhas Entidades",
            backgroundIcon: Icons.groups_3_rounded,
          ),
          if (viewModel.isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: tenant.primaryColor),
              ),
            )
          else if (viewModel.entities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(tenant),
            )
          else
            _buildEntitySliverList(viewModel, tenant),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntityDialog(context, viewModel),
        backgroundColor: tenant.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "NOVA ENTIDADE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic tenant) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.groups_3_outlined,
              size: 64,
              color: tenant.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Nenhuma entidade cadastrada",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Toque no botão abaixo para adicionar sua primeira entidade.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntitySliverList(MyEntitiesViewModel viewModel, dynamic tenant) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final EntityModel entity = viewModel.entities[index];
          return _buildEntityCard(entity, tenant, viewModel, index);
        }, childCount: viewModel.entities.length),
      ),
    );
  }

  Widget _buildEntityCard(
    EntityModel entity,
    dynamic tenant,
    MyEntitiesViewModel viewModel,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE9ECEF),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {}, // Future action?
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tenant.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        entity.type.isNotEmpty
                            ? entity.type[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: tenant.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entity.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212529),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entity.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete Button
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => _confirmDelete(context, entity, viewModel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    EntityModel entity,
    MyEntitiesViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remover Entidade"),
        content: Text(
          "Deseja realmente remover '${entity.type} - ${entity.name}'?",
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.removeEntity(entity);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "REMOVER",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
