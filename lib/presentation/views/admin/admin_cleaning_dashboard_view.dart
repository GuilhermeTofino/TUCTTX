import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../viewmodels/admin/cleaning_dashboard_viewmodel.dart';
import '../../widgets/premium_sliver_app_bar.dart';

class AdminCleaningDashboardView extends StatefulWidget {
  const AdminCleaningDashboardView({super.key});

  @override
  State<AdminCleaningDashboardView> createState() =>
      _AdminCleaningDashboardViewState();
}

class _AdminCleaningDashboardViewState
    extends State<AdminCleaningDashboardView> {
  final CleaningDashboardViewModel _viewModel =
      getIt<CleaningDashboardViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              const PremiumSliverAppBar(
                title: "Ranking de Faxina",
                backgroundIcon: Icons.dashboard_rounded,
              ),
              if (_viewModel.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_viewModel.ranking.isEmpty)
                _buildEmptyState()
              else ...[
                _buildTotalStats(),
                if (_viewModel.ranking.length >= 3) _buildPodium(),
                _buildRankingList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalStats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_viewModel.totalEvents} Faxinas",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Total computado no histórico",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _viewModel.ranking.take(3).toList();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Segundo Lugar
            _buildPodiumItem(top3[1], 2, 100),
            // Primeiro Lugar
            _buildPodiumItem(top3[0], 1, 130),
            // Terceiro Lugar
            _buildPodiumItem(top3[2], 3, 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(
    CleaningMemberStats stats,
    int position,
    double height,
  ) {
    final color = position == 1
        ? Colors.amber
        : (position == 2 ? Colors.grey[400] : Colors.orange[300]);
    return Column(
      children: [
        CircleAvatar(
          radius: position == 1 ? 30 : 25,
          backgroundColor: color!.withOpacity(0.2),
          child: Text(
            stats.name[0].toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            stats.name.split(' ').first,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "#$position",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${stats.attendanceCount} pres.",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList() {
    final list = _viewModel.ranking.length > 3
        ? _viewModel.ranking.sublist(3)
        : [];
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                "Demais Colocados",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          }
          final stats = list[index - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
              ],
            ),
            child: Row(
              children: [
                Text(
                  "${index + 3}º",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    stats.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${stats.attendanceCount} presenças",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }, childCount: list.isEmpty ? 0 : list.length + 1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Nenhuma presença registrada ainda",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
