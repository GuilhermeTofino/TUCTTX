import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/finance/domain/models/financial_models.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/receipt_submission_validator.dart';
import 'package:app_tenda/features/finance/presentation/viewmodels/finance_viewmodel.dart';
import 'package:app_tenda/features/finance/presentation/viewmodels/payment_request_viewmodel.dart';
import 'package:app_tenda/features/home/presentation/viewmodels/home_viewmodel.dart';

/// Tela em que o membro anexa o comprovante do PIX e indica os meses pagos.
class SendReceiptView extends StatefulWidget {
  const SendReceiptView({super.key});

  @override
  State<SendReceiptView> createState() => _SendReceiptViewState();
}

class _SendReceiptViewState extends State<SendReceiptView> {
  final _financeVM = getIt<FinanceViewModel>();
  final _requestVM = getIt<PaymentRequestViewModel>();
  final _homeVM = getIt<HomeViewModel>();

  final _totalController = TextEditingController();
  final _messageController = TextEditingController();

  /// Meses marcados (feeId) e o campo de valor de cada um.
  final Map<String, TextEditingController> _valueControllers = {};
  final Set<String> _selected = {};

  DateTime? _paidDate;
  File? _file;
  String? _fileName;

  @override
  void dispose() {
    _totalController.dispose();
    _messageController.dispose();
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Mensalidades que podem receber comprovante: nem pagas, nem em análise.
  List<MonthlyFeeModel> get _eligibleFees => _financeVM.monthlyFees
      .where(
        (f) =>
            f.status != FinanceStatus.paid &&
            !_requestVM.monthsUnderReview.contains(f.id),
      )
      .toList();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final picked = result?.files.single;
    if (picked?.path == null) return;
    setState(() {
      _file = File(picked!.path!);
      _fileName = picked.name;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _paidDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );
    if (date != null) setState(() => _paidDate = date);
  }

  void _toggle(MonthlyFeeModel fee, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(fee.id);
        _valueControllers.putIfAbsent(fee.id, () => TextEditingController());
      } else {
        _selected.remove(fee.id);
      }
    });
  }

  Future<void> _submit() async {
    final user = _homeVM.currentUser;
    if (user == null) return;

    final items = <PaymentRequestItem>[];
    for (final fee in _eligibleFees.where((f) => _selected.contains(f.id))) {
      final value =
          ReceiptSubmissionValidator.parseMoney(
            _valueControllers[fee.id]?.text ?? '',
          ) ??
          0;
      items.add(
        PaymentRequestItem(month: fee.month, year: fee.year, value: value),
      );
    }

    final error = await _requestVM.submit(
      user: user,
      items: items,
      totalValue: ReceiptSubmissionValidator.parseMoney(_totalController.text),
      paidDate: _paidDate,
      file: _file,
      fileName: _fileName,
      message: _messageController.text,
      fees: _financeVM.monthlyFees,
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprovante enviado! Aguarde a aprovação do financeiro.'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Enviar comprovante',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_financeVM, _requestVM]),
        builder: (context, _) {
          final fees = _eligibleFees;
          final submitting = _requestVM.isSubmitting;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Meses pagos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (fees.isEmpty)
                Text(
                  'Nenhum mês disponível para enviar comprovante.',
                  style: TextStyle(color: Colors.grey[600]),
                )
              else
                ...fees.map(_buildFeeRow),
              const SizedBox(height: 20),
              TextField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor total do comprovante (R\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _paidDate == null
                      ? 'Data do pagamento'
                      : DateFormat('dd/MM/yyyy').format(_paidDate!),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_fileName ?? 'Anexar comprovante (imagem ou PDF)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mensagem para o financeiro (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: tenant.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar para aprovação'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeeRow(MonthlyFeeModel fee) {
    final selected = _selected.contains(fee.id);
    final monthName = DateFormat(
      'MMMM',
      'pt_BR',
    ).format(DateTime(2024, fee.month)).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => _toggle(fee, v ?? false),
          ),
          Expanded(
            child: Text(
              '$monthName ${fee.year}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (selected)
            SizedBox(
              width: 110,
              child: TextField(
                controller: _valueControllers[fee.id],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  isDense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
