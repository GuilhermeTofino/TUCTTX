import 'package:flutter/material.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/features/finance/domain/pending_receipts_grouping.dart';
import 'package:app_tenda/features/finance/presentation/viewmodels/receipt_approval_viewmodel.dart';
import 'package:app_tenda/features/home/presentation/viewmodels/home_viewmodel.dart';

/// Lista de membros com comprovante aguardando aprovação.
class PendingReceiptsView extends StatefulWidget {
  const PendingReceiptsView({super.key});

  @override
  State<PendingReceiptsView> createState() => _PendingReceiptsViewState();
}

class _PendingReceiptsViewState extends State<PendingReceiptsView> {
  final _approvalVM = getIt<ReceiptApprovalViewModel>();
  final _homeVM = getIt<HomeViewModel>();

  @override
  void initState() {
    super.initState();
    if (!_approvalVM.isLoaded) _approvalVM.init(_homeVM.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Comprovantes pendentes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _approvalVM,
        builder: (context, _) {
          if (!_approvalVM.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_approvalVM.isApprover) {
            return const Center(
              child: Text('Você não tem permissão para aprovar comprovantes.'),
            );
          }
          final groups = _approvalVM.groups;
          if (groups.isEmpty) {
            return const Center(child: Text('Nenhum comprovante pendente.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildGroup(groups[index]),
          );
        },
      ),
    );
  }

  Widget _buildGroup(UserPendingGroup group) {
    final count = group.months.length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          group.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$count ${count == 1 ? 'mês' : 'meses'} aguardando'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.userPendingReceipts,
          arguments: {'userId': group.userId},
        ),
      ),
    );
  }
}
