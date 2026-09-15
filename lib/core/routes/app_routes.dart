import 'package:flutter/material.dart';

// As views antigas foram removidas nesta branch (feature/new-layout) para
// reconstrução do layout do zero. Conforme cada nova tela for criada,
// importe-a aqui e troque o placeholder correspondente pelo builder real.
//
// Exemplo:
// import 'package:app_tenda/features/auth/presentation/views/login_view.dart';
// ...
// case login:
//   return MaterialPageRoute(builder: (_) => const LoginView());

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String calendar = '/calendar';
  static const String menuManagement = '/menu-management';
  static const String adminHub = '/admin-hub';
  static const String adminMembers = '/admin-members';
  static const String financialHub = '/financial-hub';
  static const String adminAnnouncements = '/admin-announcements';
  static const String announcements = '/announcements';
  static const String studiesHub = '/studies-hub';
  static const String adminStudies = '/admin-studies';
  static const String adminCleaningDashboard = '/admin-cleaning-dashboard';
  static const String camboneList = '/cambone-list';
  static const String adminCambone = '/admin-cambone';
  static const String myEntities = '/my-entities';
  static const String houseEntities = '/admin-house-entities';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
      case login:
      case register:
      case home:
      case calendar:
      case menuManagement:
      case adminHub:
      case adminMembers:
      case financialHub:
      case adminAnnouncements:
      case announcements:
      case studiesHub:
      case adminStudies:
      case adminCleaningDashboard:
      case camboneList:
      case adminCambone:
      case myEntities:
      case houseEntities:
        return _placeholderRoute(settings.name!);

      default:
        return _errorRoute("Rota não encontrada: ${settings.name}");
    }
  }

  /// Tela temporária para rotas cuja view ainda não foi recriada nesta branch.
  static Route<dynamic> _placeholderRoute(String routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(routeName)),
        body: Center(
          child: Text('Tela ainda não implementada para "$routeName".'),
        ),
      ),
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Erro de Navegação")),
        body: Center(child: Text(message)),
      ),
    );
  }
}
