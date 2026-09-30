import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/finance/domain/models/payment_request_model.dart';
import 'package:app_tenda/features/finance/domain/repositories/payment_request_repository.dart';
import 'package:app_tenda/features/home/presentation/viewmodels/home_viewmodel.dart';

/// Destino do push "comprovante aguardando aprovação".
///
/// Nesta etapa mostra os dados da solicitação e faz a checagem de permissão;
/// a conferência do arquivo e os botões Aprovar/Rejeitar vêm na etapa seguinte.
class ReceiptReviewView extends StatefulWidget {
  final String requestId;
  const ReceiptReviewView({super.key, required this.requestId});

  @override
  State<ReceiptReviewView> createState() => _ReceiptReviewViewState();
}

class _ReceiptReviewViewState extends State<ReceiptReviewView> {
  final _repository = getIt<PaymentRequestRepository>();
  final _homeVM = getIt<HomeViewModel>();

  late final Future<_ReviewState> _future = _load();

  Future<_ReviewState> _load() async {
    final user = _homeVM.currentUser;
    if (user == null) return const _ReviewState.denied();

    try {
      final approvers = await _repository.getApproverIds();
      if (!user.isAdmin || !approvers.contains(user.id)) {
        return const _ReviewState.denied();
      }

      final request = await _repository.getRequest(widget.requestId);
      if (request == null) return const _ReviewState.notFound();
      return _ReviewState.ready(request);
    } catch (_) {
      return const _ReviewState.failed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Revisar comprovante',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<_ReviewState>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final state = snapshot.data!;
          switch (state.kind) {
            case _ReviewKind.denied:
              return _message(
                Icons.lock_outline,
                'Você não tem permissão para aprovar comprovantes.',
              );
            case _ReviewKind.notFound:
              return _message(
                Icons.search_off,
                'Esta solicitação não foi encontrada.',
              );
            case _ReviewKind.failed:
              return _message(
                Icons.error_outline,
                'Não foi possível carregar a solicitação. Tente novamente.',
              );
            case _ReviewKind.ready:
              return _buildRequest(state.request!);
          }
        },
      ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRequest(PaymentRequestModel request) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          request.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          'Pago em ${date.format(request.paidDate)} · '
          'total ${money.format(request.totalValue)}',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        ...request.items.map(
          (i) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${i.month.toString().padLeft(2, '0')}/${i.year}'),
            trailing: Text(money.format(i.value)),
            subtitle: Text(_statusLabel(i.status)),
          ),
        ),
        if (request.message != null) ...[
          const SizedBox(height: 12),
          Text('Mensagem: ${request.message}'),
        ],
      ],
    );
  }

  String _statusLabel(PaymentItemStatus status) {
    switch (status) {
      case PaymentItemStatus.pendingApproval:
        return 'Aguardando aprovação';
      case PaymentItemStatus.approved:
        return 'Aprovado';
      case PaymentItemStatus.rejected:
        return 'Rejeitado';
    }
  }
}

enum _ReviewKind { ready, denied, notFound, failed }

class _ReviewState {
  final _ReviewKind kind;
  final PaymentRequestModel? request;
  const _ReviewState._(this.kind, [this.request]);
  const _ReviewState.denied() : this._(_ReviewKind.denied);
  const _ReviewState.notFound() : this._(_ReviewKind.notFound);
  const _ReviewState.failed() : this._(_ReviewKind.failed);
  const _ReviewState.ready(PaymentRequestModel request)
    : this._(_ReviewKind.ready, request);
}
