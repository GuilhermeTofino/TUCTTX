import 'package:flutter/material.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/admin/presentation/views/admin_monthly_fees_view.dart';
import 'package:app_tenda/features/admin/presentation/views/admin_bazaar_debts_view.dart';
import 'package:app_tenda/features/admin/presentation/views/admin_amaci_view.dart';
import 'package:app_tenda/features/admin/presentation/views/admin_member_full_record_view.dart';

class MemberOptionsModal extends StatelessWidget {
  final UserModel member;

  final Future<void> Function(UserModel)? onPromoteToAdmin;

  /// Marca/desmarca o admin como aprovador de comprovantes do financeiro.
  final Future<void> Function(UserModel)? onToggleFinanceApprover;
  final bool isFinanceApprover;

  /// Visitante -> membro ("filho de santo").
  final Future<void> Function(UserModel)? onApproveVisitor;

  /// Abre a checklist de permissões (só para membros, role 'user').
  final Future<void> Function(UserModel)? onEditSkills;

  /// Membro -> visitante (perde as permissões).
  final Future<void> Function(UserModel)? onDemoteToVisitor;

  /// Histórico de mudanças de acesso, com "Desfazer".
  final Future<void> Function(UserModel)? onShowHistory;

  const MemberOptionsModal({
    super.key,
    required this.member,
    this.onPromoteToAdmin,
    this.onToggleFinanceApprover,
    this.isFinanceApprover = false,
    this.onApproveVisitor,
    this.onEditSkills,
    this.onDemoteToVisitor,
    this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF1F3F5),
                backgroundImage: member.photoUrl != null
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      member.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            "Gestão Administrativa",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOptionCard(
                context,
                title: "Mensalidade",
                icon: Icons.payments_outlined,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminMonthlyFeesView(member: member),
                    ),
                  );
                },
              ),
              _buildOptionCard(
                context,
                title: "Bazar",
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminBazaarDebtsView(member: member),
                    ),
                  );
                },
              ),
              _buildOptionCard(
                context,
                title: "Amaci",
                icon: Icons.water_drop_outlined,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminAmaciView(member: member),
                    ),
                  );
                },
              ),
              _buildOptionCard(
                context,
                title: "Ficha Completa",
                icon: Icons.assignment_outlined,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminMemberFullRecordView(member: member),
                    ),
                  );
                },
              ),
              if (onPromoteToAdmin != null)
                _buildOptionCard(
                  context,
                  title: member.isAdmin ? "Remover Admin" : "Tornar Admin",
                  icon: member.isAdmin
                      ? Icons.remove_moderator_outlined
                      : Icons.admin_panel_settings_outlined,
                  color: member.isAdmin ? Colors.red : Colors.indigo,
                  onTap: () => _showConfirmationDialog(context),
                ),
              if (member.isVisitor && onApproveVisitor != null)
                _buildOptionCard(
                  context,
                  title: member.isPendingApproval
                      ? "Aprovar (pediu acesso)"
                      : "Aprovar como Filho(a)",
                  icon: Icons.how_to_reg_outlined,
                  color: Colors.green,
                  onTap: () => _confirm(
                    context,
                    title: "Aprovar como filho(a) de santo",
                    message:
                        "${member.name} passará a ter acesso de membro (mural, estudos, financeiro e demais áreas).",
                    color: Colors.green,
                    onConfirm: () => onApproveVisitor?.call(member),
                  ),
                ),
              if (member.role == 'user' && onEditSkills != null)
                _buildOptionCard(
                  context,
                  title: "Permissões",
                  icon: Icons.tune_rounded,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.pop(context);
                    onEditSkills?.call(member);
                  },
                ),
              if (member.role == 'user' && onDemoteToVisitor != null)
                _buildOptionCard(
                  context,
                  title: "Rebaixar p/ Visitante",
                  icon: Icons.person_off_outlined,
                  color: Colors.red,
                  onTap: () => _confirm(
                    context,
                    title: "Rebaixar para visitante",
                    message:
                        "${member.name} perderá o acesso de membro e todas as permissões. Só verá o calendário.",
                    color: Colors.red,
                    onConfirm: () => onDemoteToVisitor?.call(member),
                  ),
                ),
              if (onShowHistory != null)
                _buildOptionCard(
                  context,
                  title: "Histórico",
                  icon: Icons.history_rounded,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.pop(context);
                    onShowHistory?.call(member);
                  },
                ),
              // Só admins podem ser aprovadores (as regras exigem os dois).
              if (member.isAdmin && onToggleFinanceApprover != null)
                _buildOptionCard(
                  context,
                  title: isFinanceApprover
                      ? "Remover Aprovador"
                      : "Aprovador Financeiro",
                  icon: isFinanceApprover
                      ? Icons.money_off_csred_outlined
                      : Icons.verified_user_outlined,
                  color: isFinanceApprover ? Colors.red : Colors.teal,
                  onTap: () => _showApproverDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
       ),
      ),
    );
  }

  /// Confirmação genérica; fecha o modal e executa [onConfirm].
  void _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Fecha o dialog
              Navigator.pop(context); // Fecha o modal
              onConfirm();
            },
            child: Text("Confirmar", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member.isAdmin ? "Remover Admin" : "Tornar Admin"),
        content: Text(
          member.isAdmin
              ? "Tem certeza que deseja remover as permissões de administrador de ${member.name}?"
              : "Tem certeza que deseja conceder permissões de administrador para ${member.name}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Fecha o dialog
              Navigator.pop(context); // Fecha o modal
              onPromoteToAdmin?.call(member);
            },
            child: Text(
              "Confirmar",
              style: TextStyle(
                color: member.isAdmin ? Colors.red : Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproverDialog(BuildContext context) {
    final color = isFinanceApprover ? Colors.red : Colors.teal;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isFinanceApprover ? "Remover Aprovador" : "Aprovador Financeiro",
        ),
        content: Text(
          isFinanceApprover
              ? "${member.name} deixará de aprovar comprovantes de mensalidade."
              : "${member.name} passará a receber e aprovar os comprovantes de mensalidade enviados pelos membros.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Fecha o dialog
              Navigator.pop(context); // Fecha o modal
              onToggleFinanceApprover?.call(member);
            },
            child: Text(
              "Confirmar",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
