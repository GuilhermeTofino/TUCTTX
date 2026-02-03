import 'package:app_tenda/presentation/views/admin/admin_hub_view.dart';
import 'package:app_tenda/presentation/views/admin/member_management_view.dart';
import 'package:app_tenda/presentation/views/admin/menu_management_view.dart';
import 'package:app_tenda/presentation/views/calendar_view.dart';
import 'package:app_tenda/presentation/views/finance/financial_hub_view.dart';
import 'package:app_tenda/presentation/views/home_view.dart';
import 'package:app_tenda/presentation/views/login_view.dart';
import 'package:app_tenda/presentation/views/register_view.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/presentation/views/welcome_view.dart';
// Importe aqui quando criarmos os arquivos:
// import '../../presentation/views/login_view.dart';
// import '../../presentation/views/register_view.dart';

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
