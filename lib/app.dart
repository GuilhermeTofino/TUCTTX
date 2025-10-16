import 'package:app_tenda/screens/entrar.dart';
import 'package:app_tenda/widgets/fechar_teclado.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/routes/app_routes.dart';
import 'package:app_tenda/screens/cadastro.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: MaterialApp(
        title: 'Aplicativo TUCTTX',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(color: Colors.white, elevation: 0),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        // Definimos a rota inicial e o mapa de rotas nomeadas.
        initialRoute: AppRoutes.entrar,
        routes: {
          AppRoutes.entrar: (context) => const Entrar(),
          AppRoutes.cadastro: (context) => const CadastroScreen(),
        },
      ),
    );
  }
}
