import 'dart:io';
import 'dart:ui';
import 'package:app_tenda/presentation/widgets/custom_logo_loader.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/presentation/viewmodels/home/home_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/announcements/announcement_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/finance/finance_viewmodel.dart';
import 'package:app_tenda/presentation/viewmodels/calendar/calendar_viewmodel.dart';

import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/domain/models/announcement_model.dart';
import 'package:app_tenda/core/services/version_check_service.dart';
import 'package:app_tenda/presentation/widgets/home/home_highlights_carousel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_tenda/core/services/dynamic_island/dynamic_island_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewModel _viewModel = getIt<HomeViewModel>();
  final AnnouncementViewModel _announcementVM = getIt<AnnouncementViewModel>();
  final FinanceViewModel _financeVM = getIt<FinanceViewModel>();
  final VersionCheckService _versionCheckService = getIt<VersionCheckService>();
  final CalendarViewModel _calendarVM = getIt<CalendarViewModel>();
  String? _lastAnnouncementId;

  @override
  void initState() {
    super.initState();
    _checkVersion(); // Validação de versão
    _viewModel.loadCurrentUser();
    _viewModel.addListener(_onUserLoaded);
    _announcementVM.addListener(_checkForNewAnnouncements);
    _announcementVM.loadLastSeen(AppConfig.instance.tenant.tenantSlug);
  }

  Future<void> _checkVersion() async {
    await _versionCheckService.initialize();
    final bool requiresUpdate = await _versionCheckService.isUpdateRequired();
    if (requiresUpdate && mounted) {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final primaryColor = AppConfig.instance.tenant.primaryColor;
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Nova Versão Disponível!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Para continuar aproveitando o melhor da nossa comunidade, é necessário atualizar o aplicativo.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final url = _versionCheckService.getStoreUrl();
                        if (url.isNotEmpty) {
                          launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "ATUALIZAR AGORA",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Versão desatualizada",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _checkForNewAnnouncements() {
    if (_announcementVM.announcements.isEmpty) return;

    final latest = _announcementVM.announcements.first;
    print(
      '🔔 Checking announcement: ${latest.title} (ID: ${latest.id}, Important: ${latest.isImportant})',
    );

    // Se é a primeira carga
    if (_lastAnnouncementId == null) {
      print('📌 First load - storing ID: ${latest.id}');
      _lastAnnouncementId = latest.id;

      // SEMPRE dispara avisos importantes na primeira carga (mesmo que já lidos)
      // Isso garante que o usuário veja o aviso mais recente ao abrir o app
      if (latest.isImportant) {
        print('⚠️ Triggering important announcement on first load');
        _triggerAnnouncementDI(latest);
      }
      return;
    }

    // Se mudou o ID, é um novo aviso recebido em tempo real
    if (_lastAnnouncementId != latest.id) {
      print(
        '🆕 New announcement detected! Old ID: $_lastAnnouncementId, New ID: ${latest.id}',
      );
      _lastAnnouncementId = latest.id;
      _triggerAnnouncementDI(latest);
    } else {
      print('✓ Same announcement, no action needed');
    }
  }

  void _triggerAnnouncementDI(AnnouncementModel announcement) {
    print('🚀 Triggering DI for announcement: ${announcement.title}');

    final diService = getIt<DynamicIslandService>();
    final primaryColor = AppConfig.instance.tenant.primaryColor;
    final hexColor = '#${primaryColor.value.toRadixString(16).substring(2)}';

    print('📱 Calling startAnnouncement with:');
    print('   Title: ${announcement.title}');
    print('   Content: ${announcement.content}');
    print('   Important: ${announcement.isImportant}');
    print('   Color: $hexColor');

    diService.startAnnouncement(
      title: announcement.title,
      content: announcement.content,
      isImportant: announcement.isImportant,
      primaryColor: hexColor,
    );
  }

  void _onUserLoaded() {
    if (_viewModel.currentUser != null) {
      final tenantSlug = _viewModel.currentUser!.tenantSlug;
      _announcementVM.listenToAnnouncements(tenantSlug);

      // Carregar eventos e atualizar Dynamic Island
      _calendarVM.loadEvents(tenantSlug).then((_) {
        _updateDynamicIsland();
      });
    }
  }

  void _updateDynamicIsland() {
    // Lógica para encontrar o próximo evento
    final now = DateTime.now();
    final events = _calendarVM.events;

    // Filtra eventos futuros ou de hoje que ainda não acabaram (assumindo duração de 4h por padrão se não tiver fim)
    // Para simplificar, pegamos o primeiro evento cujo início é após agora - 4 horas
    final upcomingEvents = events.where((e) {
      final eventEnd = e.date.add(const Duration(hours: 4));
      return eventEnd.isAfter(now);
    }).toList();

    // Ordena por data
    upcomingEvents.sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isNotEmpty) {
      final nextEvent = upcomingEvents.first;
      final diService = getIt<DynamicIslandService>();

      // Formata a hora HH:mm
      final hour = nextEvent.date.hour.toString().padLeft(2, '0');
      final minute = nextEvent.date.minute.toString().padLeft(2, '0');
      final timeString = "$hour:$minute";

      // Status baseado no horário
      String status = "Em breve";
      if (now.isAfter(nextEvent.date) &&
          now.isBefore(nextEvent.date.add(const Duration(hours: 4)))) {
        status = "Em andamento";
      }

      // Converte cor primária para Hex String se possível
      final primaryColor = AppConfig.instance.tenant.primaryColor;
      final hexColor = '#${primaryColor.value.toRadixString(16).substring(2)}';

      diService.startActivity(
        eventName: nextEvent.title,
        eventType: nextEvent.type,
        eventDate: timeString,
        status: status,
        eventDescription: nextEvent.description,
        primaryColor: hexColor,
      );
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onUserLoaded);
    _announcementVM.removeListener(_checkForNewAnnouncements);
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
      case 'cambone':
      case 'people':
        return Icons.people_alt_rounded;
      case 'scales':
        return Icons.view_agenda_rounded;
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
    } else if (action == 'route:/cambone-list') {
      Navigator.pushNamed(context, AppRoutes.camboneList);
    } else if (action == 'route:/admin-house-entities') {
      Navigator.pushNamed(context, AppRoutes.houseEntities);
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
              body: Column(
                children: [
                  // 1. Fixed Header
                  _buildFixedHeader(user, tenant),

                  // 2. Fixed Content (Carousel + Title)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        HomeHighlightsCarousel(
                          announcements: _announcementVM.announcements,
                          nextAmaciDate: user.nextAmaciDate,
                        ),
                        const SizedBox(height: 12),
                        _buildSectionTitle("Menu Principal"),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // 3. Horizontal Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildAnimatedMenuGrid(user, tenant),
                    ),
                  ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFixedHeader(UserModel user, tenant) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tenant.primaryColor, _darken(tenant.primaryColor, 0.15)],
        ),
      ),
      child: Stack(
        children: [
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
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopBar(user, tenant),
                  const SizedBox(height: 24),
                  _buildIdentityCard(user, tenant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(UserModel user, tenant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            _buildTopIconButton(
              Icons.settings_outlined,
              () => _showSettingsSheet(context),
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

    // Cálculos para exibir "de 4 em 4" (2x2 na tela)
    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 48.0; // 24 esquerda + 24 direita
    const double mainAxisSpacing = 12.0;
    const double crossAxisSpacing = 12.0;

    // Altura total do grid permanece fixa
    const double gridHeight = 378.0;

    // Altura de um item = (AlturaGrid - EspaçoVertical) / 2 linhas
    const double itemHeight = (gridHeight - crossAxisSpacing) / 2;

    // Largura ideal de um item para caber 2 na tela = (LarguraTela - Padding - EspaçoHorizontal) / 2
    final double itemWidth =
        (screenWidth - horizontalPadding - mainAxisSpacing) / 2;

    // Razão de aspecto = Altura / Largura (No scroll horizontal o crossAxis é a altura)
    final double aspectRatio = itemHeight / itemWidth;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          bottom: 24,
        ), // Espaço para não cortar a sombra
        scrollDirection: Axis.horizontal,
        physics:
            const PageScrollPhysics(), // Scroll paginado para dar a sensação de "4 em 4"
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 Linhas
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final menu = menus[index];
          return _buildMenuCard(
            menu.title,
            _mapIcon(menu.icon),
            _mapColor(menu.color, tenant),
            () => _handleAction(menu.action, context, user),
          );
        },
      ),
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

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Configurações",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.groups_3_outlined),
                title: const Text("Minhas Entidades"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.myEntities);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text("Termos de Uso"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);

                  const url = 'https://www.iubenda.com/privacy-policy/11447814';
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text("Política de Privacidade"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  const url = 'https://www.iubenda.com/privacy-policy/11447814';
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  "Excluir Minha Conta",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAccountDialog();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text("Excluir Conta?"),
            ],
          ),
          content: const Text(
            "Essa ação é irreversível. Todos os seus dados, histórico financeiro e perfil serão apagados permanentemente.\n\nDeseja continuar?",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  // 1. Limpa os ViewModels para cancelar streams ativos
                  // Isso evita erros de "permission-denied" quando o usuário for deletado
                  _announcementVM.clear();
                  _financeVM.clear();

                  // 2. Deleta a conta
                  await _viewModel.deleteAccount();

                  if (mounted) {
                    // 3. Exibe mensagem ANTES de navegar (enquanto o contexto é válido)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Conta excluída com sucesso."),
                      ),
                    );

                    // 4. Navega para Login
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll("Exception: ", ""),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("SIM, EXCLUIR"),
            ),
          ],
        );
      },
    );
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
