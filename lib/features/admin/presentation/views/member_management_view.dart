import 'package:app_tenda/presentation/viewmodels/admin/member_management_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/user_model.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/admin/member_options_modal.dart';

import '../../widgets/premium_sliver_app_bar.dart';

class MemberManagementView extends StatefulWidget {
  const MemberManagementView({super.key});

  @override
  State<MemberManagementView> createState() => _MemberManagementViewState();
}

class _MemberManagementViewState extends State<MemberManagementView> {
  final MemberManagementViewModel _viewModel =
      getIt<MemberManagementViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.loadMembers();
  }

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
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (_viewModel.members.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("Nenhum membro encontrado.")),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final member = _viewModel.members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMemberCard(member),
                    );
                  }, childCount: _viewModel.members.length),
                ),
              );
            },
          ),
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
                            member.role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
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
        onPromoteToAdmin: _viewModel.toggleAdminRole,
      ),
    );
  }
}
