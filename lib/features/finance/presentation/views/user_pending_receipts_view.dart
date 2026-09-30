import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/features/finance/presentation/viewmodels/receipt_approval_viewmodel.dart';

/// Meses de um membro com comprovante aguardando aprovação.
class UserPendingReceiptsView extends StatelessWidget {
  final String userId;
  const UserPendingReceiptsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final approvalVM = getIt<ReceiptApprovalViewModel>();
    final tenant = AppConfig.instance.tenant;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return ListenableBuilder(
      listenable: approvalVM,
      builder: (context, _) {
        final group = approvalVM.groupFor(userId);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              group?.userName ?? 'Comprovantes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: tenant.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: group == null
              ? const Center(child: Text('Nenhum comprovante pendente.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: group.months.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pending = group.months[index];
                    final item = pending.item;
                    final monthName = DateFormat('MMMM', 'pt_BR')
                        .format(DateTime(2024, item.month))
                        .toUpperCase();
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          '$monthName ${item.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(money.format(item.value)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.receiptReview,
                          arguments: {'requestId': pending.request.id},
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
