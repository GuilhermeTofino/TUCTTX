import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/presentation/viewmodels/finance_viewmodel.dart';
import 'package:app_tenda/presentation/views/admin/admin_monthly_fees_view.dart';
import 'package:app_tenda/presentation/views/admin/admin_bazaar_debts_view.dart';

import '../../widgets/premium_sliver_app_bar.dart';

class AdminMemberFullRecordView extends StatefulWidget {
  final UserModel member;

  const AdminMemberFullRecordView({super.key, required this.member});

  @override
  State<AdminMemberFullRecordView> createState() =>
      _AdminMemberFullRecordViewState();
}

class _AdminMemberFullRecordViewState extends State<AdminMemberFullRecordView> {
  final _financeVM = getIt<FinanceViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _financeVM.listenToFinancialData(
        widget.member.tenantSlug,
        widget.member.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListenableBuilder(
        listenable: _financeVM,
        builder: (context, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const PremiumSliverAppBar(
                title: "Ficha Completa",
                backgroundIcon: Icons.badge_outlined,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildIdentityHeader(context),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Dados Pessoais"),
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Saúde e Emergência"),
                      _buildHealthInfoCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Situação Financeira"),
                      _buildFinanceSummaryCard(context),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Vida Espiritual"),
                      _buildSpiritualInfoCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Histórico e Datas"),
                      _buildHistoryCard(),
                      const SizedBox(height: 40),
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

  Widget _buildFinanceSummaryCard(BuildContext context) {
    // Cálculos Financeiros
    final fees = _financeVM.monthlyFees;
    final debts = _financeVM.bazaarDebts;

    final pendingFees = fees
        .where((f) => f.status != FinanceStatus.paid)
        .length;
    final totalBazaarDebt = debts
        .where((d) => !d.isPaid)
        .fold(0.0, (sum, d) => sum + d.value);

    return _buildCard(
      children: [
        // Seção Mensalidade
        _buildFinanceRow(
          context,
          title: "Mensalidades",
          statusWidget: _buildFinanceStatusBadge(
            label: pendingFees == 0 ? "EM DIA" : "$pendingFees PENDENTES",
            color: pendingFees == 0 ? Colors.green : Colors.orange,
          ),
          icon: Icons.calendar_today,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminMonthlyFeesView(member: widget.member),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(),
        ),
        // Seção Bazar
        _buildFinanceRow(
          context,
          title: "Dívida Bazar",
          statusWidget: Text(
            totalBazaarDebt > 0
                ? "R\$ ${totalBazaarDebt.toStringAsFixed(2)}"
                : "Nada consta",
            style: TextStyle(
              color: totalBazaarDebt > 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          icon: Icons.shopping_bag_outlined,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminBazaarDebtsView(member: widget.member),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinanceRow(
    BuildContext context, {
    required String title,
    required Widget statusWidget,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  statusWidget,
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceStatusBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[100],
            backgroundImage: widget.member.photoUrl != null
                ? NetworkImage(widget.member.photoUrl!)
                : null,
            child: widget.member.photoUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.member.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.member.role == 'admin'
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.member.role.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.member.role == 'admin'
                    ? Colors.purple
                    : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      children: [
        _buildInfoRow(Icons.email_outlined, "Email", widget.member.email),
        const Divider(),
        _buildInfoRow(
          Icons.phone_outlined,
          "Telefone",
          widget.member.phone.isNotEmpty
              ? widget.member.phone
              : "Não informado",
          onTap: widget.member.phone.isNotEmpty
              ? () => _launchUrl("tel:${widget.member.phone}")
              : null,
          actionIcon: Icons.call,
        ),
        const Divider(),
        _buildInfoRow(
          Icons.calendar_today_outlined,
          "Cadastrado em",
          widget.member.createdAt != null
              ? DateFormat('dd/MM/yyyy').format(widget.member.createdAt!)
              : "Desconhecido",
        ),
      ],
    );
  }

  Widget _buildHealthInfoCard() {
    return _buildCard(
      borderColor: Colors.red.withOpacity(0.2),
      backgroundColor: Colors.red.withOpacity(0.02),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                Icons.bloodtype,
                "Tipo Sanguíneo",
                widget.member.tipoSanguineo ?? "Não inf.",
                iconColor: Colors.red,
              ),
            ),
            if (widget.member.emergencyContact.isNotEmpty)
              IconButton(
                onPressed: () =>
                    _launchUrl("tel:${widget.member.emergencyContact}"),
                icon: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.sos, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
        const Divider(),
        _buildInfoRow(
          Icons.contact_phone_outlined,
          "Contato de Emergência",
          widget.member.emergencyContact.isNotEmpty
              ? widget.member.emergencyContact
              : "Não informado",
          iconColor: Colors.red,
        ),
        const Divider(),
        _buildInfoList(
          "Alergias",
          widget.member.alergias,
          Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 12),
        _buildInfoList(
          "Medicamentos",
          widget.member.medicamentos,
          Icons.medication_outlined,
        ),
        const SizedBox(height: 12),
        _buildInfoList(
          "Condições Médicas",
          widget.member.condicoesMedicas,
          Icons.favorite_border,
        ),
      ],
    );
  }

  Widget _buildSpiritualInfoCard() {
    return _buildCard(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOrixaBadge(
                "Frente",
                widget.member.orixaFrente,
                _getOrixaColor(widget.member.orixaFrente),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOrixaBadge(
                "Juntó",
                widget.member.orixaJunto,
                _getOrixaColor(widget.member.orixaJunto),
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        _buildSwitchRow(
          "Já tirou santo?",
          widget.member.jaTirouSanto,
          Icons.check_circle_outline,
        ),
        const Divider(),
        _buildSwitchRow(
          "Jogou com o Kangamba",
          widget.member.jogoComTata,
          Icons.sports_esports_outlined, // Icone ilustrativo
        ),
      ],
    );
  }

  Widget _buildHistoryCard() {
    final nextAmaci = widget.member.nextAmaciDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.member.nextAmaciDate!)
        : "Não agendado";

    final lastAmaci = widget.member.lastAmaciDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.member.lastAmaciDate!)
        : "Sem registro";

    return _buildCard(
      children: [
        _buildInfoRow(
          Icons.water_drop,
          "Próximo Amaci",
          nextAmaci,
          iconColor: Colors.blue,
          valueColor: Colors.blue[800],
          isBold: true,
        ),
        const Divider(),
        _buildInfoRow(Icons.history, "Último Amaci", lastAmaci),
      ],
    );
  }

  // --- Helpers ---

  Widget _buildCard({
    required List<Widget> children,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? Colors.black.withOpacity(0.05),
        ),
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
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
    Color? valueColor,
    bool isBold = false,
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (actionIcon != null)
              Icon(actionIcon, size: 20, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoList(String title, String? content, IconData icon) {
    if (content == null || content.isEmpty) {
      return _buildInfoRow(icon, title, "Item não informado");
    }

    final items = content.split('\n').where((e) => e.isNotEmpty).toList();
    if (items.length <= 1) {
      return _buildInfoRow(icon, title, content, iconColor: Colors.red);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.red[300]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(item),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.red.withOpacity(0.2)),
              labelStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.all(0),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOrixaBadge(String type, String? orixa, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            orixa ?? "A definir",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.green.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? "SIM" : "NÃO",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrixaColor(String? orixaName) {
    if (orixaName == null) return Colors.grey;
    final name = orixaName.toLowerCase();
    if (name.contains('ogum')) return const Color(0xFF2196F3);
    if (name.contains('oxum')) return const Color(0xFFFFD700);
    if (name.contains('iemanjá') ||
        name.contains('iemanja') ||
        name.contains('yemanjá'))
      return const Color(0xFF00BCD4);
    if (name.contains('oxóssi') || name.contains('oxossi'))
      return const Color(0xFF4CAF50);
    if (name.contains('iansã') ||
        name.contains('iansa') ||
        name.contains('yansã'))
      return const Color(0xFFB71C1C);
    if (name.contains('xangô') || name.contains('xango'))
      return const Color(0xFF795548);
    if (name.contains('nanã')) return const Color(0xFF9C27B0);
    if (name.contains('oxalá') || name.contains('oxaguian'))
      return const Color(0xFFBDBDBD);
    return Colors.grey;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
