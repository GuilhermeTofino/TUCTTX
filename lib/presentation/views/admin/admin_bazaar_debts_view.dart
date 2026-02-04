import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/domain/repositories/finance_repository.dart';
import 'package:app_tenda/presentation/viewmodels/finance_viewmodel.dart';

import '../../widgets/premium_sliver_app_bar.dart';

class AdminBazaarDebtsView extends StatefulWidget {
  final UserModel member;

  const AdminBazaarDebtsView({super.key, required this.member});

  @override
  State<AdminBazaarDebtsView> createState() => _AdminBazaarDebtsViewState();
}

class _AdminBazaarDebtsViewState extends State<AdminBazaarDebtsView> {
  final _financeVM = getIt<FinanceViewModel>();
  final _itemController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _financeVM.listenToFinancialData(
      widget.member.tenantSlug,
      widget.member.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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

          return CustomScrollView(
            slivers: [
              PremiumSliverAppBar(
                title: "Bazar: ${widget.member.name.split(' ')[0]}",
                backgroundIcon: Icons.shopping_bag_rounded,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddDebtCard(tenant.primaryColor),
                      const SizedBox(height: 32),
                      if (unpaidDebts.isNotEmpty) ...[
                        const Text(
                          "Dívidas Ativas",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...unpaidDebts.map(
                          (d) => _buildDebtItem(d, isPaid: false),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (paidDebts.isNotEmpty) ...[
                        const Text(
                          "Histórico de Pagamentos",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...paidDebts.map(
                          (d) => _buildDebtItem(d, isPaid: true),
                        ),
                      ],
                      if (unpaidDebts.isEmpty && paidDebts.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              "Nenhuma movimentação no bazar.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddDebtCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Registrar Nova Compra",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _itemController,
            decoration: const InputDecoration(
              labelText: "Item",
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Valor (R\$)",
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addDebt,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "ADICIONAR DÍVIDA",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
        color: isPaid
            ? (Colors.grey[50] ?? Colors.white).withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? Colors.transparent : Colors.orange.withOpacity(0.2),
        ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "R\$ ${debt.value.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPaid ? Colors.grey : Colors.orange[800],
                ),
              ),
              if (!isPaid)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await _financeVM.sendBazaarReminder(
                          widget.member,
                          debt.itemName,
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Lembrete de bazar enviado!"),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      tooltip: "Enviar Lembrete",
                    ),
                    TextButton(
                      onPressed: () =>
                          _financeVM.payDebt(widget.member.id, debt.id),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        "BAIXA",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _addDebt() async {
    final item = _itemController.text;
    final valueStr = _valueController.text.replaceAll(',', '.');
    final value = double.tryParse(valueStr);

    if (item.isNotEmpty && value != null) {
      final newDebt = BazaarDebtModel(
        id: '', // Firestore gera
        userId: widget.member.id,
        itemName: item,
        value: value,
        date: DateTime.now(),
      );

      await getIt<FinanceRepository>().addBazaarDebt(newDebt);
      _itemController.clear();
      _valueController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Dívida registrada!")));
      }
    }
  }
}
