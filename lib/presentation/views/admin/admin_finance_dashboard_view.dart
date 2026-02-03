import 'package:flutter/material.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/domain/repositories/finance_repository.dart';
import 'package:app_tenda/domain/repositories/user_repository.dart';

class AdminFinanceDashboardView extends StatefulWidget {
  const AdminFinanceDashboardView({super.key});

  @override
  State<AdminFinanceDashboardView> createState() =>
      _AdminFinanceDashboardViewState();
}

class _AdminFinanceDashboardViewState extends State<AdminFinanceDashboardView> {
  final _userRepo = getIt<UserRepository>();
  bool _isLoading = true;
  List<UserModel> _allUsers = [];
  Map<String, List<MonthlyFeeModel>> _userFees = {};
  Map<String, List<BazaarDebtModel>> _userDebts = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final users = await _userRepo.getAllUsers();
    final Map<String, List<MonthlyFeeModel>> fees = {};
    final Map<String, List<BazaarDebtModel>> debts = {};
    final financeRepo = getIt<FinanceRepository>();

    for (final user in users) {
      // Busca o primeiro snapshot dos streams
      final feesList = await financeRepo
          .getUserMonthlyFees(user.tenantSlug, user.id)
          .first;
      final debtsList = await financeRepo
          .getUserBazaarDebts(user.tenantSlug, user.id)
          .first;

      fees[user.id] = feesList;
      debts[user.id] = debtsList;
    }

    if (mounted) {
      setState(() {
        _allUsers = users;
        _userFees = fees;
        _userDebts = debts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Dashboard Financeiro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTotalizersSection(),
                  const SizedBox(height: 32),
                  _buildTopDebtorsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalizersSection() {
    // Totalizadores de Mensalidades
    double feesPaid = 0;
    double feesPending = 0;
    double feesLate = 0;

    for (final userId in _userFees.keys) {
      final fees = _userFees[userId] ?? [];
      for (final fee in fees) {
        if (fee.status == FinanceStatus.paid) {
          feesPaid += fee.value;
        } else if (fee.status == FinanceStatus.pending) {
          feesPending += fee.value;
        } else if (fee.status == FinanceStatus.late) {
          feesLate += fee.value;
        }
      }
    }

    // Totalizadores de Bazar
    double bazaarPaid = 0;
    double bazaarPending = 0;

    for (final userId in _userDebts.keys) {
      final debts = _userDebts[userId] ?? [];
      for (final debt in debts) {
        if (debt.isPaid) {
          bazaarPaid += debt.value;
        } else {
          bazaarPending += debt.value;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de Mensalidades
        const Text(
          "💰 Mensalidades",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTotalizerCard(
                "Arrecadado",
                feesPaid,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTotalizerCard(
                "Pendente",
                feesPending,
                Colors.orange,
                Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTotalizerCard(
          "Em Atraso",
          feesLate,
          Colors.red,
          Icons.warning_amber_rounded,
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),

        // Seção de Bazar
        const Text(
          "🛍️ Bazar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTotalizerCard(
                "Arrecadado",
                bazaarPaid,
                Colors.teal,
                Icons.shopping_bag,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTotalizerCard(
                "Pendente",
                bazaarPending,
                Colors.deepOrange,
                Icons.pending_actions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalizerCard(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "R\$ ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDebtorsSection() {
    // Calcula dívidas totais por usuário (bazar não pago)
    final Map<String, double> userDebtsTotal = {};

    for (final userId in _userDebts.keys) {
      final debts = _userDebts[userId] ?? [];
      final unpaidDebts = debts.where((d) => !d.isPaid);
      final total = unpaidDebts.fold<double>(
        0,
        (sum, debt) => sum + debt.value,
      );
      if (total > 0) {
        userDebtsTotal[userId] = total;
      }
    }

    // Ordena por maior dívida
    final sortedDebtors = userDebtsTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedDebtors.take(5).toList();

    if (top5.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "🎉 Nenhuma pendência no Bazar!",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Maiores Pendências (Bazar)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top5.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = top5[index];
              final user = _allUsers.firstWhere((u) => u.id == entry.key);
              final position = index + 1;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Text(
                    "#$position",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  "R\$ ${entry.value.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
