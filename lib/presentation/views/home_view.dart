import 'dart:io';
import 'package:app_tenda/presentation/widgets/custom_logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/app_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/routes/app_routes.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../domain/models/user_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewModel _viewModel = getIt<HomeViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.loadCurrentUser();
  }

  // --- HELPERS PARA MENUS DINÂMICOS ---

  IconData _mapIcon(String iconKey) {
    switch (iconKey) {
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'finance':
        return Icons.account_balance_wallet_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'documents':
        return Icons.description_outlined;
      default:
        return Icons.help_outline; // Ícone padrão para desconhecidos
    }
  }

  Color _mapColor(String colorKey, dynamic tenant) {
    switch (colorKey) {
      case 'primary':
        return tenant.primaryColor;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.redAccent;
      case 'blue':
        return Colors.blue;
      default:
        // Tenta parsear hex se não for chave conhecida (ex: #FF0000)
        if (colorKey.startsWith('#')) {
          return Color(int.parse(colorKey.replaceFirst('#', '0xFF')));
        }
        return tenant.primaryColor;
    }
  }

  void _handleAction(String action, BuildContext context, UserModel user) {
    if (action == 'route:/calendar') {
      Navigator.pushNamed(context, AppRoutes.calendar);
    } else if (action == 'internal:health') {
      _showHealthDetailsSheet(context, user);
    } else if (action == 'internal:coming_soon') {
      _showComingSoonSnackBar();
    } else {
      // Ação desconhecida
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ação inválida ou não implementada.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final user = _viewModel.currentUser;

        if (_viewModel.isLoading || user == null) {
          return const Scaffold(body: Center(child: CustomLogoLoader()));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Column(
            children: [
              _buildFixedTopSection(user, tenant),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  // MUDANÇA 1: Diminuímos o padding superior de 24 para 12 (ou 8)
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Menu Principal"),

                      // MUDANÇA 2: Diminuímos o SizedBox de 16 para 8
                      const SizedBox(height: 0),

                      _buildAnimatedMenuGrid(user, tenant),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFixedTopSection(UserModel user, tenant) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tenant.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tenant.primaryColor, _darken(tenant.primaryColor, 0.1)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            children: [
              _buildTopBar(user, tenant),
              const SizedBox(height: 20),
              _buildIdentityCard(user, tenant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(UserModel user, tenant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Olá, ${user.name.split(' ')[0]}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Bem-vindo(a)",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _viewModel.signOut().then(
              (_) => Navigator.pushReplacementNamed(context, AppRoutes.login),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuGrid(UserModel user, tenant) {
    final menus = _viewModel.menus;

    if (menus.isEmpty && !_viewModel.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text("Nenhum menu disponível.")),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 150)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildMenuCard(
            menu.title,
            _mapIcon(menu.icon),
            _mapColor(menu.color, tenant),
            () => _handleAction(menu.action, context, user),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL DE SAÚDE ---
  void _showHealthDetailsSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dados de Saúde",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildHealthInfoRow(
              Icons.bloodtype,
              "Tipo Sanguíneo",
              user.tipoSanguineo ?? "N/I",
            ),
            _buildHealthInfoRow(
              Icons.warning_amber,
              "Alergias",
              user.alergias?.isEmpty ?? true
                  ? "Nenhuma informada"
                  : user.alergias!,
            ),
            _buildHealthInfoRow(
              Icons.medication,
              "Medicamentos",
              user.medicamentos?.isEmpty ?? true
                  ? "Nenhum informado"
                  : user.medicamentos!,
            ),
            _buildHealthInfoRow(
              Icons.favorite_border,
              "Condições",
              user.condicoesMedicas?.isEmpty ?? true
                  ? "Nenhuma informada"
                  : user.condicoesMedicas!,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- IDENTITY CARD ---
  Widget _buildIdentityCard(UserModel user, tenant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(user, tenant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBloodBadge(user.tipoSanguineo ?? "N/I"),
            ],
          ),
          const Divider(height: 32, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrixaItem(
                "Frente",
                user.orixaFrente ?? "A definir",
                _getOrixaColor(user.orixaFrente),
              ),
              _buildOrixaItem(
                "Juntó",
                user.orixaJunto ?? "A definir",
                _getOrixaColor(user.orixaJunto),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user, tenant) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: tenant.primaryColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFF1F3F5),
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, color: Colors.grey, size: 30)
                : null,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tenant.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- AUXILIARES ---
  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Funcionalidade em breve!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enviando foto...")));
      final success = await _viewModel.updateProfilePicture(File(image.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "Foto atualizada!" : "Erro ao enviar foto.",
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // Seus métodos _buildOrixaItem, _buildBloodBadge, _buildSectionTitle, _darken e _getOrixaColor permanecem os mesmos...
  Widget _buildOrixaItem(String label, String name, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
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
}
