import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/app_config.dart';
import '../../widgets/premium_sliver_app_bar.dart';
import 'monthly_fees_view.dart';
import 'bazaar_debts_view.dart';

class FinancialHubView extends StatelessWidget {
  const FinancialHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const PremiumSliverAppBar(
            title: "Financeiro",
            backgroundIcon: Icons.account_balance_wallet_rounded,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selecione uma categoria",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Acompanhe suas responsabilidades financeiras com o terreiro.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _buildFinanceCard(
                    context,
                    title: "Minhas Mensalidades",
                    subtitle: "Histórico de pagamentos mensais",
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MonthlyFeesView(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFinanceCard(
                    context,
                    title: "Meu Bazar",
                    subtitle: "Itens adquiridos e pendências",
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BazaarDebtsView(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (tenant.pixKey != null || tenant.paymentLink != null) ...[
                    const Text(
                      "Formas de Pagamento",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentInfoCard(context, tenant),
                    const SizedBox(height: 32),
                  ],
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Mantenha suas contas em dia para ajudar na manutenção da nossa casa.",
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
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

  Widget _buildFinanceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(BuildContext context, TenantConfig tenant) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          if (tenant.pixKey != null) ...[
            Row(
              children: [
                const Icon(Icons.pix, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "Chave PIX",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tenant.pixKey!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tenant.pixKey!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Chave PIX copiada!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          if (tenant.pixKey != null && tenant.paymentLink != null)
            const SizedBox(height: 20),
          if (tenant.paymentLink != null) ...[
            Row(
              children: [
                const Icon(Icons.link, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "Link de Pagamento",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                /* DISABLED BY USER REQUEST
                onPressed: () async {
                  try {
                    final uri = Uri.parse(tenant.paymentLink!);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Não foi possível abrir o link de pagamento",
                          ),
                        ),
                      );
                    }
                  }
                },
                */
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text("ABRIR LINK DE PAGAMENTO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tenant.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
