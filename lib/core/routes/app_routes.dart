import 'package:app_tenda/presentation/views/admin/admin_hub_view.dart';
import 'package:app_tenda/presentation/views/admin/member_management_view.dart';
import 'package:app_tenda/presentation/views/admin/menu_management_view.dart';
import 'package:app_tenda/presentation/views/calendar/calendar_view.dart';
import 'package:app_tenda/presentation/views/finance/financial_hub_view.dart';
import 'package:app_tenda/presentation/views/admin/admin_announcements_view.dart';
import 'package:app_tenda/presentation/views/admin/admin_studies_view.dart';
import 'package:app_tenda/presentation/views/admin/admin_cleaning_dashboard_view.dart';
import 'package:app_tenda/presentation/views/announcements/announcements_view.dart';
import 'package:app_tenda/presentation/views/home/home_view.dart';
import 'package:app_tenda/presentation/views/auth/login_view.dart';
import 'package:app_tenda/presentation/views/auth/register_view.dart';
import 'package:app_tenda/presentation/views/studies/studies_hub_view.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/presentation/views/auth/welcome_view.dart';
// Importe aqui quando criarmos os arquivos:
// import '../../presentation/views/auth/login_view.dart';
// import '../../presentation/views/auth/register_view.dart';

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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeView());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());

      case register:
        // Por enquanto retornamos o erro até você me mandar o arquivo da RegisterView
        return MaterialPageRoute(builder: (_) => const RegisterView());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeView());

      case calendar:
        final args = settings.arguments as Map<String, dynamic>?;
        final isAdminMode = args?['isAdminMode'] ?? false;
        return MaterialPageRoute(
          builder: (_) => CalendarView(isAdminMode: isAdminMode),
        );

      case menuManagement:
        return MaterialPageRoute(builder: (_) => const MenuManagementView());

      case adminHub:
        return MaterialPageRoute(builder: (_) => const AdminHubView());

      case adminMembers:
        return MaterialPageRoute(builder: (_) => const MemberManagementView());

      case financialHub:
        return MaterialPageRoute(builder: (_) => const FinancialHubView());

      case adminAnnouncements:
        return MaterialPageRoute(
          builder: (_) => const AdminAnnouncementsView(),
        );

      case announcements:
        return MaterialPageRoute(builder: (_) => const AnnouncementsView());

      case studiesHub:
        return MaterialPageRoute(builder: (_) => const StudiesHubView());

      case adminStudies:
        return MaterialPageRoute(builder: (_) => const AdminStudiesView());

      case adminCleaningDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminCleaningDashboardView(),
        );

      default:
        return _errorRoute("Rota não encontrada: ${settings.name}");
    }
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
