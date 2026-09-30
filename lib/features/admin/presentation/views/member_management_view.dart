import 'package:app_tenda/features/admin/domain/member_tabs.dart';
import 'package:app_tenda/features/admin/presentation/viewmodels/member_management_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_tenda/features/admin/presentation/widgets/member_options_modal.dart';
import 'package:app_tenda/features/admin/presentation/widgets/skills_dialog.dart';
import 'package:app_tenda/features/admin/presentation/widgets/audit_history_sheet.dart';

import 'package:app_tenda/core/widgets/premium_sliver_app_bar.dart';

class MemberManagementView extends StatefulWidget {
  const MemberManagementView({super.key});

  @override
  State<MemberManagementView> createState() => _MemberManagementViewState();
}

class _MemberManagementViewState extends State<MemberManagementView>
    with SingleTickerProviderStateMixin {
  final MemberManagementViewModel _viewModel =
      getIt<MemberManagementViewModel>();
  late final TabController _tabs = TabController(
    length: MemberTab.values.length,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _viewModel.loadMembers();
    // Sem TabBarView (a tela é uma CustomScrollView): a aba escolhida só decide qual lista mostrar.
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  MemberTab get _currentTab => MemberTab.values[_tabs.index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const PremiumSliverAppBar(
            title: "Membros do Terreiro",
            backgroundIcon: Icons.people_alt_rounded,
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _buildTabBar(),
            ),
          ),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final list = _viewModel.membersFor(_currentTab);
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(_emptyMessage(_currentTab))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemberCard(list[index]),
                    );
                  }, childCount: list.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _emptyMessage(MemberTab tab) {
    if (_viewModel.searchQuery.trim().isNotEmpty) {
      return "Ninguém encontrado nesta aba.";
    }
    switch (tab) {
      case MemberTab.visitors:
        return "Nenhum consulente.";
      case MemberTab.members:
        return "Nenhum membro encontrado.";
      case MemberTab.admins:
        return "Nenhum administrador.";
    }
  }

  Widget _buildTabBar() {
    final pending = _viewModel.pendingApprovalMembers.length;

    Tab tab(String label, MemberTab t, {bool dot = false}) => Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label (${_viewModel.countFor(t)})"),
          if (dot) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: [
          // O ponto laranja avisa que há consulente esperando aprovação.
          tab("Consulentes", MemberTab.visitors, dot: pending > 0),
          tab("Membros", MemberTab.members),
          tab("Admins", MemberTab.admins),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        onChanged: _viewModel.updateSearch,
        decoration: InputDecoration(
          hintText: "Buscar por nome ou e-mail...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF1F3F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildMemberCard(UserModel member) {
    return GestureDetector(
      onTap: () => _showMemberOptions(member),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF1F3F5),
                backgroundImage: member.photoUrl != null
                    ? CachedNetworkImageProvider(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _roleLabel(member),
                            style: TextStyle(
                              color: member.isPendingApproval ? Colors.orange : Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            member.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberOptions(UserModel member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemberOptionsModal(
        member: member,
        onPromoteToAdmin: (m) => _run(
          () => _viewModel.toggleAdminRole(m),
          m.isAdmin
              ? "${m.name} não é mais administrador(a)."
              : "${m.name} agora é administrador(a).",
        ),
        isFinanceApprover: _viewModel.isFinanceApprover(member.id),
        onToggleFinanceApprover: _toggleFinanceApprover,
        onApproveVisitor: (m) => _run(
          () => _viewModel.approveVisitor(m),
          "${m.name} agora é filho(a) de santo.",
        ),
        onEditSkills: _editSkills,
        onDemoteToVisitor: (m) => _run(
          () => _viewModel.demoteToVisitor(m),
          "${m.name} foi rebaixado(a) para consulente.",
        ),
        onShowHistory: (m) => showAuditHistorySheet(
          context,
          member: m,
          viewModel: _viewModel,
        ),
      ),
    );
  }

  String _roleLabel(UserModel member) {
    if (member.isPendingApproval && member.isVisitor) return "CONSULENTE · PEDIU ACESSO";
    switch (member.role) {
      case 'admin':
        return "ADMIN";
      case 'user':
        final n = member.skills.length;
        return n == 0 ? "MEMBRO" : "MEMBRO · $n ${n == 1 ? 'PERMISSÃO' : 'PERMISSÕES'}";
      default:
        return "CONSULENTE";
    }
  }

  /// Executa uma mudança de acesso e mostra o resultado (ou o motivo da recusa).
  Future<void> _run(Future<void> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } on StateError catch (e) {
      // Travas de negócio (ex.: alterar o próprio acesso, último admin).
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Não foi possível concluir. Tente novamente.")),
      );
    }
  }

  Future<void> _editSkills(UserModel member) async {
    final catalog = await _viewModel.loadSkillsCatalog();
    if (!mounted) return;
    final chosen = await showSkillsDialog(context, member: member, catalog: catalog);
    if (chosen == null) return;
    await _run(
      () => _viewModel.setSkills(member, chosen),
      "Permissões de ${member.name.split(' ').first} atualizadas.",
    );
  }

  Future<void> _toggleFinanceApprover(UserModel member) async {
    final wasApprover = _viewModel.isFinanceApprover(member.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _viewModel.toggleFinanceApprover(member);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasApprover
                ? "${member.name} não é mais aprovador do financeiro."
                : "${member.name} agora é aprovador do financeiro.",
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Não foi possível alterar o aprovador. Tente novamente."),
        ),
      );
    }
  }
}
