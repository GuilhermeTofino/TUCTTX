import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../viewmodels/admin/house_entities_viewmodel.dart';
import '../../widgets/premium_sliver_app_bar.dart';

class HouseEntitiesView extends StatelessWidget {
  const HouseEntitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<HouseEntitiesViewModel>()..loadHouseEntities(),
      child: const _HouseEntitiesContent(),
    );
  }
}

class _HouseEntitiesContent extends StatelessWidget {
  const _HouseEntitiesContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HouseEntitiesViewModel>(context);
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PremiumSliverAppBar(
            title: "Entidades da Casa",
            backgroundIcon: Icons.groups_3_rounded,
          ),

          // Barra de Pesquisa
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: _buildSearchBar(viewModel, tenant),
            ),
          ),

          if (viewModel.isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: tenant.primaryColor),
              ),
            )
          else if (viewModel.errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          else if (viewModel.groupedEntities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(tenant, viewModel.searchQuery.isNotEmpty),
            )
          else
            _buildGroupedList(viewModel, tenant),
        ],
      ),
    );
  }

  Widget _buildSearchBar(HouseEntitiesViewModel viewModel, dynamic tenant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: viewModel.setSearchQuery,
        decoration: InputDecoration(
          hintText: "Buscar entidade ou médium...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: tenant.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic tenant, bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
            size: 64,
            color: tenant.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? "Nenhum resultado para a busca"
                : "Nenhuma entidade encontrada",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(HouseEntitiesViewModel viewModel, dynamic tenant) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final type = viewModel.groupedEntities.keys.elementAt(index);
          final items = viewModel.groupedEntities[type]!;
          return _buildTypeSection(type, items, tenant);
        }, childCount: viewModel.groupedEntities.length),
      ),
    );
  }

  Widget _buildTypeSection(
    String type,
    List<HouseEntityItem> items,
    dynamic tenant,
  ) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          key: PageStorageKey(type),
          title: Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
              letterSpacing: 1.2,
            ),
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tenant.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                items.length.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tenant.primaryColor,
                ),
              ),
            ),
          ),
          iconColor: tenant.primaryColor,
          collapsedIconColor: Colors.grey[400],
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: items
              .map((item) => _buildEntityCard(item, tenant))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEntityCard(HouseEntityItem item, dynamic tenant) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tenant.primaryColor,
                  tenant.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                item.entity.name.isNotEmpty
                    ? item.entity.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.entity.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212529),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.userName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
