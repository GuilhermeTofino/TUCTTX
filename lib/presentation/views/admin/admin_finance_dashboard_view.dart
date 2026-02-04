import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/domain/models/financial_goal_model.dart';
import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/domain/repositories/finance_repository.dart';
import 'package:app_tenda/domain/repositories/user_repository.dart';
import 'package:app_tenda/presentation/viewmodels/finance_viewmodel.dart';
import 'package:app_tenda/presentation/widgets/admin/goal_progress_card.dart';
import '../../widgets/premium_sliver_app_bar.dart';

class AdminFinanceDashboardView extends StatefulWidget {
  const AdminFinanceDashboardView({super.key});

  @override
  State<AdminFinanceDashboardView> createState() =>
      _AdminFinanceDashboardViewState();
}

class _AdminFinanceDashboardViewState extends State<AdminFinanceDashboardView> {
  final _userRepo = getIt<UserRepository>();
  final _financeVM = getIt<FinanceViewModel>();

  bool _isLoading = true;
  List<UserModel> _allUsers = [];
  Map<String, List<MonthlyFeeModel>> _userFees = {};
  Map<String, List<BazaarDebtModel>> _userDebts = {};

  // State UI
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isAnnualView = false; // Toggle entre Mensal e Anual

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Escuta metas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _financeVM.listenToGoals(
        AppConfig.instance.tenant.tenantSlug,
        _selectedYear,
      );
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final users = await _userRepo.getAllUsers();
    final Map<String, List<MonthlyFeeModel>> fees = {};
    final Map<String, List<BazaarDebtModel>> debts = {};
    final financeRepo = getIt<FinanceRepository>();

    for (final user in users) {
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

  // --- Calculations ---

  double _calculateTotalRecieved() {
    double total = 0;

    // Mensalidades
    for (final list in _userFees.values) {
      for (final fee in list) {
        bool matchesPeriod = _isAnnualView
            ? fee.year == _selectedYear
            : fee.year == _selectedYear && fee.month == _selectedMonth;

        if (matchesPeriod && fee.status == FinanceStatus.paid) {
          total += fee.value;
        }
      }
    }

    for (final list in _userDebts.values) {
      for (final debt in list) {
        if (!debt.isPaid) continue;

        // Usa data do pagamento se dispo, senao data da divida (fallback)
        final effectiveDate = debt.paidAt ?? debt.date;

        bool matchesPeriod = _isAnnualView
            ? effectiveDate.year == _selectedYear
            : effectiveDate.year == _selectedYear &&
                  effectiveDate.month == _selectedMonth;

        if (matchesPeriod) {
          total += debt.value;
        }
      }
    }

    return total;
  }

  // Totais PENDENTES (Atrasado + Pendente)
  double _calculateTotalPending() {
    double total = 0;
    for (final list in _userFees.values) {
      for (final fee in list) {
        bool matchesPeriod = _isAnnualView
            ? fee.year == _selectedYear
            : fee.year == _selectedYear && fee.month == _selectedMonth;

        if (matchesPeriod && fee.status != FinanceStatus.paid) {
          total += fee.value;
        }
      }
    }
    // Bazar Pendente
    for (final list in _userDebts.values) {
      for (final debt in list) {
        final date = debt.date;
        bool matchesPeriod = _isAnnualView
            ? date.year == _selectedYear
            : date.year == _selectedYear && date.month == _selectedMonth;

        if (matchesPeriod && !debt.isPaid) {
          total += debt.value;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    // Dados Calculados
    final totalRecieved = _calculateTotalRecieved();
    final totalPending = _calculateTotalPending();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: "Financeiro",
                  backgroundIcon: Icons.analytics_rounded,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadDashboardData,
                    ),
                  ],
                ),
                ListenableBuilder(
                  listenable: _financeVM,
                  builder: (context, _) {
                    double currentTarget = _isAnnualView
                        ? _financeVM.getAnnualGoal(_selectedYear)
                        : _financeVM.getMonthlyGoal(
                            _selectedMonth,
                            _selectedYear,
                          );

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPeriodSelector(tenant),
                            const SizedBox(height: 24),

                            // Hero Progress Card
                            GoalProgressCard(
                              title: _isAnnualView
                                  ? "Meta Anual ($_selectedYear)"
                                  : "Meta de ${DateFormat('MMMM', 'pt_BR').format(DateTime(_selectedYear, _selectedMonth))}",
                              current: totalRecieved,
                              target: currentTarget,
                              baseColor: tenant.primaryColor,
                              onEditGoal: () => _showSetGoalModal(
                                context,
                                currentTarget,
                                _isAnnualView,
                                _selectedMonth,
                                _selectedYear,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Mini Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMiniStatCard(
                                    "Pendente",
                                    totalPending,
                                    Colors.orange,
                                    Icons.pending_actions,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMiniStatCard(
                                    "Bazar (Total)",
                                    _calculateLegacyBazaarTotal(),
                                    Colors.teal,
                                    Icons.shopping_bag_outlined,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            const Text(
                              "Top Pendências",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTopDebtorsList(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  double _calculateLegacyBazaarTotal() {
    // Retorna total de divida de bazar (open) INDEPENDENTE de data, snapshot atual
    double total = 0;
    for (final list in _userDebts.values) {
      total += list.where((d) => !d.isPaid).fold(0.0, (s, d) => s + d.value);
    }
    return total;
  }

  Widget _buildPeriodSelector(tenant) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildPeriodTab("MENSAL", !_isAnnualView, () {
            setState(() => _isAnnualView = false);
          }, tenant),
          _buildPeriodTab("ANUAL", _isAnnualView, () {
            setState(() => _isAnnualView = true);
          }, tenant),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(
    String text,
    bool isActive,
    VoidCallback onTap,
    tenant,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isActive ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(
              symbol: "R\$",
              locale: "pt_BR",
            ).format(value), // Formata
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDebtorsList() {
    // Reutiliza logica de sort
    final Map<String, double> userDebtsTotal = {};

    for (final userId in _userDebts.keys) {
      final debts = _userDebts[userId] ?? [];
      final unpaidDebts = debts.where((d) => !d.isPaid);
      final total = unpaidDebts.fold<double>(
        0,
        (sum, debt) => sum + debt.value,
      );
      if (total > 0) userDebtsTotal[userId] = total;
    }

    final sortedDebtors = userDebtsTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedDebtors.take(5).toList();

    if (top5.isEmpty) return const Text("Sem pendências!");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: top5.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = top5[index];
        final user = _allUsers.firstWhere(
          (u) => u.id == entry.key,
          orElse: () => UserModel(
            id: '?',
            name: 'Desconhecido',
            email: '',
            role: 'user',
            createdAt: DateTime.now(),

            tenantSlug: '',
            phone: '',
            emergencyContact: '',
            jaTirouSanto: false,
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(
                "#${index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: "R\$",
                  locale: "pt_BR",
                ).format(entry.value),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetGoalModal(
    BuildContext context,
    double currentValue,
    bool isAnnual,
    int month,
    int year,
  ) {
    final controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAnnual
                  ? "Definir Meta Anual ($year)"
                  : "Definir Meta de ${DateFormat('MMMM', 'pt_BR').format(DateTime(year, month))}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Valor da Meta (R\$)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: "R\$ ",
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final val =
                      double.tryParse(controller.text.replaceAll(',', '.')) ??
                      0.0;
                  _financeVM.saveGoal(
                    FinancialGoalModel(
                      id: '', // repo generates ID logic
                      tenantId: AppConfig.instance.tenant.tenantSlug,
                      type: isAnnual
                          ? FinancialGoalType.annual
                          : FinancialGoalType.monthly,
                      year: year,
                      month: isAnnual ? null : month,
                      targetValue: val,
                      updatedAt: DateTime.now(),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.instance.tenant.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("SALVAR META"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
