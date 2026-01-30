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
              // --- ÁREA FIXA (HEADER + CARD) ---
              _buildFixedTopSection(user, tenant),

              // --- ÁREA ROÁVEL (MENUS) ---
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Menu Principal"),
                      const SizedBox(height: 16),
                      _buildAnimatedMenuGrid(tenant),
                      const SizedBox(height: 40),
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

  // Widget que agrupa o fundo colorido e o card de identidade fixos
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
              "Axé, ${user.name.split(' ')[0]}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tenant.onPrimaryColor,
              ),
            ),
            Text(
              "Seus fundamentos estão em dia",
              style: TextStyle(
                fontSize: 14,
                color: tenant.onPrimaryColor.withOpacity(0.8),
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
            icon: Icon(Icons.logout, color: tenant.onPrimaryColor),
            onPressed: () => _viewModel.signOut().then(
              (_) => Navigator.pushReplacementNamed(context, AppRoutes.welcome),
            ),
          ),
        ),
      ],
    );
  }

  // Grid que aplica a animação em cascata nos cards
  Widget _buildAnimatedMenuGrid(tenant) {
    final menus = [
      {
        'title': 'Trabalhos',
        'icon': Icons.calendar_today_outlined,
        'color': tenant.primaryColor,
      },
      {
        'title': 'Mensalidades',
        'icon': Icons.account_balance_wallet_outlined,
        'color': Colors.green,
      },
      {
        'title': 'Saúde',
        'icon': Icons.health_and_safety_outlined,
        'color': Colors.redAccent,
      },
      {
        'title': 'Documentos',
        'icon': Icons.description_outlined,
        'color': Colors.blue,
      },
    ];

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
        // Lógica de delay para o efeito cascata
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
            menus[index]['title'] as String,
            menus[index]['icon'] as IconData,
            menus[index]['color'] as Color,
          ),
        );
      },
    );
  }

  // --- MÉTODOS AUXILIARES E VISUAIS ---

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
                    Text(
                      "Filho de Santo",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                _getOrixaColor(user.orixaFrente), // <-- COR DINÂMICA
              ),
              _buildOrixaItem(
                "Juntó",
                user.orixaJunto ?? "A definir",
                _getOrixaColor(user.orixaJunto), // <-- COR DINÂMICA
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
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
          onTap: () {},
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
            // Se o usuário tiver photoUrl, carrega a imagem, senão mostra o ícone
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, color: Colors.grey, size: 30)
                : null,
          ),
        ),
        // Botão de Editar Foto
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _pickAndUploadImage(), // Vamos criar este método
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();

    // 1. O usuário escolhe a imagem (galeria ou câmera)
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Comprime para não pesar no Firebase
    );

    if (image != null) {
      // 2. Mostra um feedback de carregamento (opcional, mas recomendado)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enviando foto...")));

      // 3. Chama a ViewModel para fazer o upload pesado
      // Precisaremos criar este método 'updateProfilePicture' na HomeViewModel
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

  Color _getOrixaColor(String? orixaName) {
    if (orixaName == null) return Colors.grey;

    final name = orixaName.toLowerCase();

    if (name.contains('ogum'))
      return const Color(0xFF2196F3); // Azul ou Vermelho (depende da vertente)
    if (name.contains('oxum'))
      return const Color(0xFFFFD700); // Dourado/Amarelo
    if (name.contains('iemanjá') || name.contains('iemanja'))
      return const Color(0xFF00BCD4); // Azul Claro
    if (name.contains('oxóssi') || name.contains('oxossi'))
      return const Color(0xFF4CAF50); // Verde
    if (name.contains('iansã') || name.contains('iansa'))
      return const Color(0xFFB71C1C); // Vermelho/Vinho
    if (name.contains('xangô') || name.contains('xango'))
      return const Color(0xFF795548); // Marrom
    if (name.contains('omolu') || name.contains('obaluaiê'))
      return const Color(0xFF212121); // Preto/Palha
    if (name.contains('nanã')) return const Color(0xFF9C27B0); // Lilás/Roxo
    if (name.contains('oxalá')) return const Color(0xFF9E9E9E); // Branco/Prata

    return Colors.grey; // Cor padrão para nomes não reconhecidos
  }
}
