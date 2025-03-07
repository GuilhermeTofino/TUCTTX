import 'package:app_tenda/calendario.dart';

import 'package:app_tenda/screens/bazar.dart';
import 'package:app_tenda/screens/cadastrar.dart';
import 'package:app_tenda/detalhes.dart';
import 'package:app_tenda/entrar.dart';
import 'package:app_tenda/home.dart';
import 'package:app_tenda/login.dart';
import 'package:app_tenda/mensalidade.dart';
import 'package:app_tenda/perfil_usuario.dart';
import 'package:app_tenda/screens/cadastro_produto.dart';
import 'package:app_tenda/solicitar_item_bazar.dart';
import 'package:app_tenda/splash.dart';
import 'package:app_tenda/widgets/fechar_teclado.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(color: Colors.white, elevation: 0),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const Login(),
        routes: {
          '/login': (context) => const Login(),
          '/cadastrar': (context) => const Cadastrar(),
          '/entrar': (context) => const Entrar(),
          '/tela_principal': (context) => const Home(),
          '/calendario': (context) => const Calendario(),
          '/perfilUsuario': (context) => const PerfilUsuario(),
          '/mensalidade': (context) => const Mensalidade(),
          '/detalhesFilho': (context) => const DetalhesFilho(),
          '/bazar': (context) => const BazarScreen(),
          '/solicitar_produto': (context) => const SolicitarProdutoScreen(),
          '/cadastro_produto': (context) => const CadastroProdutoScreen(),
        },
      ),
    );
  }
}
