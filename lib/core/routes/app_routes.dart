import 'package:app_tenda/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
// Importe suas futuras telas aqui
// import '../../presentation/views/login_view.dart';
// import '../../presentation/views/register_view.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeView());

      case login:
        // return MaterialPageRoute(builder: (_) => const LoginView());
        return _errorRoute(); // Temporário até criarmos a view

      case register:
        // return MaterialPageRoute(builder: (_) => const RegisterView());
        return _errorRoute(); // Temporário até criarmos a view

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) =>
          Scaffold(body: Center(child: Text('Rota não encontrada'))),
    );
  }
}
