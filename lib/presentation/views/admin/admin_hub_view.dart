import 'package:flutter/material.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/presentation/views/admin/admin_finance_dashboard_view.dart';
import 'package:app_tenda/presentation/widgets/premium_sliver_app_bar.dart';

class AdminHubView extends StatelessWidget {
  const AdminHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const PremiumSliverAppBar(
            title: "Painel Administrativo",
            backgroundIcon: Icons.admin_panel_settings_rounded,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gerenciamento",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Escolha uma área para administrar",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildAdminCard(
                        context,
                        title: "Atalhos",
                        subtitle: "Menus da Home",
                        icon: Icons.grid_view_rounded,
                        color: Colors.blue,
                        route: AppRoutes.menuManagement,
                      ),
                      _buildAdminCard(
                        context,
                        title: "Membros",
                        subtitle: "Lista de Filhos",
                        icon: Icons.people_alt_rounded,
                        color: Colors.orange,
                        route: AppRoutes.adminMembers,
                      ),
                      _buildAdminCard(
                        context,
                        title: "Financeiro",
                        subtitle: "Dashboard",
                        icon: Icons.analytics_rounded,
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminFinanceDashboardView(),
                          ),
                        ),
                      ),
                      _buildAdminCard(
                        context,
                        title: "Escalas",
                        subtitle: "Giras e Faxina",
                        icon: Icons.calendar_month_rounded,
                        color: Colors.green,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.calendar,
                          arguments: {'isAdminMode': true},
                        ),
                      ),
                      _buildAdminCard(
                        context,
                        title: "Avisos",
                        subtitle: "Enviar Push",
                        icon: Icons.notification_add_rounded,
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminAnnouncements,
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        title: "Estudos",
                        subtitle: "Gerenciar PDFs",
                        icon: Icons.library_books_rounded,
                        color: Colors.indigo,
                        route: AppRoutes.adminStudies,
                      ),
                      _buildAdminCard(
                        context,
                        title: "Ranking Faxina",
                        subtitle: "Estatísticas de presença",
                        icon: Icons.analytics_rounded,
                        color: Colors.teal,
                        route: AppRoutes.adminCleaningDashboard,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? route,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap ?? () => Navigator.pushNamed(context, route!),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
