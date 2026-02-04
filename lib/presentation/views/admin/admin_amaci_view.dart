import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../viewmodels/member_management_viewmodel.dart';
import '../../../domain/models/user_model.dart';
import '../../widgets/custom_logo_loader.dart';

import '../../widgets/premium_sliver_app_bar.dart';

class AdminAmaciView extends StatefulWidget {
  final UserModel member;

  const AdminAmaciView({super.key, required this.member});

  @override
  State<AdminAmaciView> createState() => _AdminAmaciViewState();
}

class _AdminAmaciViewState extends State<AdminAmaciView> {
  late DateTime? _lastAmaciDate;
  late DateTime? _nextAmaciDate;
  bool _isSaving = false;
  final _viewModel = getIt<MemberManagementViewModel>();

  @override
  void initState() {
    super.initState();
    _lastAmaciDate = widget.member.lastAmaciDate;
    _nextAmaciDate = widget.member.nextAmaciDate;
  }

  Future<void> _selectDate(BuildContext context, bool isNext) async {
    final initialDate = isNext
        ? (_nextAmaciDate ?? DateTime.now().add(const Duration(days: 7)))
        : (_lastAmaciDate ?? DateTime.now().subtract(const Duration(days: 30)));

    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (newDate != null) {
      setState(() {
        if (isNext) {
          _nextAmaciDate = newDate;
        } else {
          _lastAmaciDate = newDate;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await _viewModel.saveAmaciDates(
        widget.member,
        _lastAmaciDate,
        _nextAmaciDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Datas de Amaci salvas com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isSaving
          ? const Center(child: CustomLogoLoader())
          : CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: "Amaci: ${widget.member.name.split(' ')[0]}",
                  backgroundIcon: Icons.water_drop_rounded,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 32),
                        _buildDatePicker(
                          "Último Amaci",
                          "Data em que o último amaci foi realizado.",
                          _lastAmaciDate,
                          Icons.history,
                          Colors.grey,
                          () => _selectDate(context, false),
                        ),
                        const SizedBox(height: 24),
                        _buildDatePicker(
                          "Próximo Amaci",
                          "Data agendada para o próximo amaci.\n(Envia notificação ao salvar)",
                          _nextAmaciDate,
                          Icons.event,
                          Colors.blue,
                          () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "SALVAR DATAS",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Gestão de Amaci",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Configure as datas de obrigação litúrgica do membro.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    String title,
    String subtitle,
    DateTime? date,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final dateStr = date != null
        ? DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(date)
        : "Não definida";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: date != null ? Colors.black87 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
