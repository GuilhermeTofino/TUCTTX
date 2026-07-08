import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/presentation/viewmodels/finance/finance_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/home/home_viewmodel.dart';

class BazaarDebtsView extends StatefulWidget {
  const BazaarDebtsView({super.key});

  @override
  State<BazaarDebtsView> createState() => _BazaarDebtsViewState();
}

class _BazaarDebtsViewState extends State<BazaarDebtsView> {
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
          "Meu Bazar",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _financeVM,
        builder: (context, _) {
          if (_financeVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unpaidDebts = _financeVM.bazaarDebts
              .where((d) => !d.isPaid)
              .toList();
          final paidDebts = _financeVM.bazaarDebts
              .where((d) => d.isPaid)
              .toList();

          if (unpaidDebts.isEmpty && paidDebts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (unpaidDebts.isNotEmpty) ...[
                const Text(
                  "Pendências Atuais",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...unpaidDebts.map((d) => _buildDebtItem(d, isPaid: false)),
                const SizedBox(height: 32),
              ],
              if (paidDebts.isNotEmpty) ...[
                const Text(
                  "Histórico de Compras",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ...paidDebts.map((d) => _buildDebtItem(d, isPaid: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Você não possui compras registradas no bazar.",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(BazaarDebtModel debt, {required bool isPaid}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPaid
            ? null
            : [
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPaid ? Colors.grey[200] : Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check : Icons.shopping_basket_outlined,
              color: isPaid ? Colors.grey : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isPaid ? TextDecoration.lineThrough : null,
                    color: isPaid ? Colors.grey : Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(debt.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            "R\$ ${debt.value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPaid ? Colors.grey : Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }
}
