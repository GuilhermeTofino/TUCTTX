import 'package:app_tenda/presentation/views/home_view.dart';
import 'package:app_tenda/presentation/views/login_view.dart';
import 'package:app_tenda/presentation/views/register_view.dart';
import 'package:flutter/material.dart';
import '../../presentation/views/welcome_view.dart';
// Importe aqui quando criarmos os arquivos:
// import '../../presentation/views/login_view.dart';
// import '../../presentation/views/register_view.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home'; // Adicionado para a Home após o login

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
