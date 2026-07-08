import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/presentation/viewmodels/finance/finance_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/home/home_viewmodel.dart';

class MonthlyFeesView extends StatefulWidget {
  const MonthlyFeesView({super.key});

  @override
  State<MonthlyFeesView> createState() => _MonthlyFeesViewState();
}

class _MonthlyFeesViewState extends State<MonthlyFeesView> {
  final _financeVM = getIt<FinanceViewModel>();
  final _homeVM = getIt<HomeViewModel>();

  @override
  void initState() {
    super.initState();
    final user = _homeVM.currentUser;
    if (user != null) {
      _financeVM.listenToFinancialData(user.tenantSlug, user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Minhas Mensalidades",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _financeVM,
        builder: (context, _) {
          if (_financeVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_financeVM.monthlyFees.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _financeVM.monthlyFees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final fee = _financeVM.monthlyFees[index];
              return _buildFeeCard(fee);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma mensalidade registrada.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(MonthlyFeeModel fee) {
    final monthName = _getMonthName(fee.month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(fee.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                fee.month.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: _getStatusColor(fee.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$monthName ${fee.year}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Valor: R\$ ${fee.value.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          _buildStatusBadge(fee.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FinanceStatus status) {
    String label = "";
    Color color = Colors.grey;
    IconData icon = Icons.help_outline;

    switch (status) {
      case FinanceStatus.paid:
        label = "PAGO";
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case FinanceStatus.pending:
        label = "PENDENTE";
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case FinanceStatus.late:
        label = "ATRASADO";
        color = Colors.red;
        icon = Icons.priority_high;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FinanceStatus status) {
    switch (status) {
      case FinanceStatus.paid:
        return Colors.green;
      case FinanceStatus.pending:
        return Colors.orange;
      case FinanceStatus.late:
        return Colors.red;
    }
  }

  String _getMonthName(int month) {
    final date = DateTime(2024, month);
    return DateFormat('MMMM', 'pt_BR').format(date).toUpperCase();
  }
}
