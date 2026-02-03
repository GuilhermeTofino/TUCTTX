import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/domain/models/financial_models.dart';
import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/presentation/viewmodels/finance_viewmodel.dart';

class AdminMonthlyFeesView extends StatefulWidget {
  final UserModel member;

  const AdminMonthlyFeesView({super.key, required this.member});

  @override
  State<AdminMonthlyFeesView> createState() => _AdminMonthlyFeesViewState();
}

class _AdminMonthlyFeesViewState extends State<AdminMonthlyFeesView> {
  final _financeVM = getIt<FinanceViewModel>();

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
      appBar: AppBar(
        title: Text(
          "Mensalidades: ${widget.member.name.split(' ')[0]}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sincronizar Ano Atual",
            onPressed: _showSyncDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _financeVM,
        builder: (context, _) {
          if (_financeVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_financeVM.monthlyFees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Nenhuma mensalidade encontrada."),
                  ElevatedButton(
                    onPressed: _showSyncDialog,
                    child: const Text("Sincronizar Ano Atual"),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _financeVM.monthlyFees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final fee = _financeVM.monthlyFees[index];
              return _buildAdminFeeCard(fee);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminFeeCard(MonthlyFeeModel fee) {
    final monthName = _getMonthName(fee.month);

    return InkWell(
      onTap: () => _showStatusPicker(fee),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getStatusColor(fee.status).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  fee.month.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: _getStatusColor(fee.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  fee.year.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
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
      ),
    );
  }

  void _showStatusPicker(MonthlyFeeModel fee) {
    final valueController = TextEditingController(
      text: fee.value.toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mudar Status e Valor",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Valor Contribuído (R\$)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 24),
            if (fee.status != FinanceStatus.paid) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _financeVM.sendFeeReminder(
                      widget.member,
                      _getMonthName(fee.month),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Lembrete enviado ao filho!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text("ENVIAR LEMBRETE (PUSH)"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            _buildStatusOption(
              fee,
              FinanceStatus.paid,
              "PAGO",
              Colors.green,
              valueController,
            ),
            _buildStatusOption(
              fee,
              FinanceStatus.pending,
              "PENDENTE",
              Colors.orange,
              valueController,
            ),
            _buildStatusOption(
              fee,
              FinanceStatus.late,
              "ATRASADO",
              Colors.red,
              valueController,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    MonthlyFeeModel fee,
    FinanceStatus status,
    String label,
    Color color,
    TextEditingController valueController,
  ) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final newValue = double.tryParse(
          valueController.text.replaceAll(',', '.'),
        );

        await _financeVM.updateStatus(
          widget.member.id,
          fee.id,
          status,
          value: newValue,
        );

        if (mounted) Navigator.pop(context);

        // Se marcou como pago, oferece enviar comprovante
        if (status == FinanceStatus.paid && mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text("Pagamento confirmado!"),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: "ENVIAR COMPROVANTE",
                onPressed: () =>
                    _sendWhatsAppReceipt(fee, newValue ?? fee.value),
                textColor: Colors.yellow,
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text("Mensalidade de $label salva com sucesso!")),
          );
        }
      },
      trailing: fee.status == status
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
    );
  }

  Future<void> _sendWhatsAppReceipt(MonthlyFeeModel fee, double value) async {
    final phone = widget.member.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefone do membro não cadastrado")),
      );
      return;
    }

    final name = widget.member.name.split(' ')[0];
    final monthName = _getMonthName(fee.month);
    final message =
        "Olá $name! Confirmamos o recebimento da sua mensalidade de "
        "$monthName/${fee.year} no valor de R\$ ${value.toStringAsFixed(2)}. Axé! 🙏";

    final url =
        "whatsapp://send?phone=55$phone&text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);

    try {
      // Tenta abrir o app do WhatsApp
      await launchUrl(uri);
    } catch (e) {
      // Se falhar, tenta o link web
      try {
        final webUrl =
            "https://wa.me/55$phone?text=${Uri.encodeComponent(message)}";
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro ao abrir WhatsApp")),
          );
        }
      }
    }
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sincronizar Ano"),
        content: const Text(
          "Deseja criar os registros de mensalidade para os 12 meses do ano atual?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              // Valor default fixo por enquanto ou configurável
              await _financeVM.syncCurrentYear(widget.member.id, 100.0);
              messenger.showSnackBar(
                const SnackBar(content: Text("Ano sincronizado com sucesso!")),
              );
            },
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FinanceStatus status) {
    String label = "";
    Color color = Colors.grey;

    switch (status) {
      case FinanceStatus.paid:
        label = "PAGO";
        color = Colors.green;
        break;
      case FinanceStatus.pending:
        label = "PENDENTE";
        color = Colors.orange;
        break;
      case FinanceStatus.late:
        label = "ATRASADO";
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
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
