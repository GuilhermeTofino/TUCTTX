import 'dart:io';
import 'dart:ui';
import 'package:app_tenda/presentation/widgets/custom_logo_loader.dart';
import 'package:app_tenda/presentation/widgets/amaci_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/app_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/routes/app_routes.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/announcement_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/finance_viewmodel.dart';
import 'package:app_tenda/domain/models/announcement_model.dart';
import '../../domain/models/user_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewModel _viewModel = getIt<HomeViewModel>();
  final AnnouncementViewModel _announcementVM = getIt<AnnouncementViewModel>();
  final FinanceViewModel _financeVM = getIt<FinanceViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.loadCurrentUser();
    _viewModel.addListener(_onUserLoaded);
    _announcementVM.loadLastSeen(AppConfig.instance.tenant.tenantSlug);
  }

  void _onUserLoaded() {
    if (_viewModel.currentUser != null) {
      _announcementVM.listenToAnnouncements(_viewModel.currentUser!.tenantSlug);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onUserLoaded);
    super.dispose();
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
      case 'school':
        return Icons.school_outlined;
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
    } else if (action == 'internal:finance' || action == 'route:/finance') {
      Navigator.pushNamed(context, AppRoutes.financialHub);
    } else if (action == 'internal:studies' ||
        action == 'route:/studies' ||
        action == 'studies' ||
        action == '/studies') {
      Navigator.pushNamed(context, AppRoutes.studiesHub);
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

        return ListenableBuilder(
          listenable: _announcementVM,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverHeader(user, tenant),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        // Banner de Aviso Importante
                        Builder(
                          builder: (context) {
                            final list = _announcementVM.announcements;
                            if (list.isEmpty) return const SizedBox.shrink();

                            final important = list
                                .where((a) => a.isImportant)
                                .toList();
                            if (important.isEmpty)
                              return const SizedBox.shrink();

                            final latest = important.first;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.announcements,
                                ),
                                child: _buildAnnouncementBanner(latest),
                              ),
                            );
                          },
                        ),

                        AmaciCard(nextAmaciDate: user.nextAmaciDate),
                        const SizedBox(height: 12),
                        _buildSectionTitle("Menu Principal"),
                        const SizedBox(height: 12),
                        _buildAnimatedMenuGrid(user, tenant),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliverHeader(UserModel user, tenant) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: tenant.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient & Pattern
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tenant.primaryColor,
                    _darken(tenant.primaryColor, 0.15),
                  ],
                ),
              ),
            ),
            // Watermark Icon
            Positioned(
              right: -50,
              top: -20,
              child: Icon(
                Icons.temple_hindu_rounded,
                size: 250,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildTopBar(user, tenant),
                    const Spacer(),
                    _buildIdentityCard(user, tenant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementBanner(AnnouncementModel latest) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.orange[400]!.withOpacity(0.5),
            Colors.orange[100]!.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flash_on_rounded,
                            size: 12,
                            color: Colors.orange[900],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "AVISO IMPORTANTE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange[900],
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            Text(
              "Bem-vindo(a)",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (user.role == 'admin')
              _buildTopIconButton(
                Icons.admin_panel_settings_outlined,
                () => Navigator.pushNamed(context, AppRoutes.adminHub),
              ),
            const SizedBox(width: 8),
            _buildTopIconButton(
              Icons.notifications_active_outlined,
              () => Navigator.pushNamed(context, AppRoutes.announcements),
              showBadge: _announcementVM.hasUnread,
            ),
            const SizedBox(width: 8),
            _buildTopIconButton(Icons.logout_rounded, () {
              _announcementVM.clear();
              _financeVM.clear();
              _viewModel.signOut().then(
                (_) => Navigator.pushReplacementNamed(context, AppRoutes.login),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTopIconButton(
    IconData icon,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onTap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
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
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Colors.grey[800],
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- IDENTITY CARD (Premium Glassmorphism) ---
  Widget _buildIdentityCard(UserModel user, tenant) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.role == 'admin'
                              ? "Administrador"
                              : "Filho(a) de Santo",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppConfig.instance.tenant.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
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
