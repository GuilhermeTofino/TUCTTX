import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routes/app_routes.dart';
import '../../viewmodels/cambone/cambone_viewmodel.dart';
import '../../viewmodels/auth/register_viewmodel.dart';
import '../../widgets/custom_logo_loader.dart';
import '../../widgets/premium_sliver_app_bar.dart';
import 'admin_cambone_view.dart'; // Added import

class CamboneListView extends StatefulWidget {
  final bool isAdminMode;
  const CamboneListView({super.key, this.isAdminMode = false});

  @override
  State<CamboneListView> createState() => _CamboneListViewState();
}

class _CamboneListViewState extends State<CamboneListView> {
  final _viewModel = getIt<CamboneViewModel>();
  final _authVM = getIt<RegisterViewModel>();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    _viewModel.fetchSchedules(AppConfig.instance.tenant.tenantSlug);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: (widget.isAdminMode && _authVM.isAdmin)
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.adminCambone);
                _loadSchedules(); // Recarrega ao voltar
              },
              backgroundColor: tenant.primaryColor,
              child: const Icon(
                Icons.edit_calendar_rounded,
                color: Colors.white,
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          const PremiumSliverAppBar(
            title: "Escala de Cambones",
            backgroundIcon: Icons.people_alt_rounded,
          ),
          SliverFillRemaining(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const Center(child: CustomLogoLoader());
                }

                if (_viewModel.error != null) {
                  return Center(
                    child: Text(
                      "Erro: ${_viewModel.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (_viewModel.schedules.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhuma escala encontrada.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  itemCount: _viewModel.schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _viewModel.schedules[index];
                    return _buildScheduleCard(schedule, tenant);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(schedule, tenant) {
    final dateStr = DateFormat("dd", 'pt_BR').format(schedule.date);
    final monthStr = DateFormat(
      "MMM",
      'pt_BR',
    ).format(schedule.date).toUpperCase().replaceAll('.', '');
    final weekDay = DateFormat('EEEE', 'pt_BR').format(schedule.date);
    final eventTitle = schedule.eventTitle ?? "Escala de Cambones";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tenant.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: tenant.primaryColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tenant.primaryColor.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            eventTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
          subtitle: Text(
            weekDay[0].toUpperCase() + weekDay.substring(1),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: (widget.isAdminMode && _authVM.isAdmin)
              ? PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminCamboneView(scheduleToEdit: schedule),
                        ),
                      );
                      _loadSchedules();
                    } else if (value == 'delete') {
                      _confirmDelete(schedule);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 12),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text('Excluir'),
                            ],
                          ),
                        ),
                      ],
                )
              : const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
          children: schedule.assignments.map<Widget>((assignment) {
            return _buildAssignmentItem(assignment, tenant, schedule);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAssignmentItem(assignment, tenant, schedule) {
    // Tenta encontrar o usuário do cambone para mostrar a foto
    final camboneUser = _viewModel.findUserByName(assignment.camboneName);
    final currentUser = _authVM.currentUser;
    final isCurrentCambone =
        currentUser != null && camboneUser?.id == currentUser.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar do Cambone
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isCurrentCambone
                        ? tenant.primaryColor
                        : tenant.primaryColor.withOpacity(0.2),
                    width: isCurrentCambone ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tenant.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: camboneUser?.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(camboneUser!.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: camboneUser?.photoUrl == null
                    ? Icon(Icons.person, color: tenant.primaryColor, size: 24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tenant.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "CAMBONE",
                            style: TextStyle(
                              color: tenant.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (isCurrentCambone) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tenant.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "VOCÊ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.camboneName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCurrentCambone
                            ? tenant.primaryColor
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lista de Médiuns
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: assignment.mediums.map<Widget>((mediumName) {
                        final mediumUser = _viewModel.findUserByName(
                          mediumName,
                        );
                        final isCurrentMedium =
                            currentUser != null &&
                            mediumUser?.id == currentUser.id;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentMedium
                                ? tenant.primaryColor.withOpacity(0.15)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentMedium
                                  ? tenant.primaryColor
                                  : Colors.grey[200]!,
                              width: isCurrentMedium ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: isCurrentMedium
                                    ? Colors.white
                                    : Colors.grey[300],
                                backgroundImage: mediumUser?.photoUrl != null
                                    ? NetworkImage(mediumUser!.photoUrl!)
                                    : null,
                                child: mediumUser?.photoUrl == null
                                    ? Text(
                                        mediumName.isNotEmpty
                                            ? mediumName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: isCurrentMedium
                                              ? tenant.primaryColor
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                mediumName.split(
                                  ' ',
                                )[0], // Só o primeiro nome para economizar espaço
                                style: TextStyle(
                                  color: isCurrentMedium
                                      ? tenant.primaryColor
                                      : Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: isCurrentMedium
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              if (isCurrentMedium) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: tenant.primaryColor,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Linha divisória sutil se não for o último
          if (schedule.assignments.last != assignment)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 64),
              child: Divider(color: Colors.grey[100], height: 1),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(schedule) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Excluir Escala?"),
          content: const Text(
            "Tem certeza que deseja excluir esta escala? Essa ação não pode ser desfeita.",
          ),
          actions: [
            TextButton(
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Excluir"),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _viewModel.deleteSchedule(
                  schedule.id,
                  AppConfig.instance.tenant.tenantSlug,
                );
                if (!mounted) return;
                if (_viewModel.error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Escala excluída com sucesso!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
