// ignore: file_names
import 'package:app_tenda/globals/app_colors.dart';
import 'package:app_tenda/routes/app_routes.dart';
import 'package:app_tenda/widgets/gradient_container.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Versão ${info.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos MediaQuery para obter o tamanho da tela e ajudar no posicionamento responsivo.
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GradientContainer(
        child: SafeArea(
          // Mantemos o SafeArea para evitar que o conteúdo fique sob a barra de status
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Container para o logo, para controlar o tamanho e o posicionamento.
                  Padding(
                    // Um padding na parte inferior para "empurrar" o logo um pouco para cima do centro.
                    padding: const EdgeInsets.only(bottom: 48.0),
                    child: Image.asset('images/logo_TUCTTX.png',
                        // Definimos uma altura para o logo para que ele não fique muito grande em telas maiores.
                        height: screenSize.height * 0.6),
                  ),

                  // Espaçamento entre o logo e o primeiro botão.
                  const SizedBox(height: 48.0),

                  // Botão de Entrar
                  ElevatedButton(
                    onPressed: () {
                      // A lógica de login virá aqui no futuro.
                      print('Botão Entrar pressionado');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary, // 3. Usamos a cor primária
                      foregroundColor: AppColors.textOnPrimary, // Cor do texto
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'ENTRAR',
                    ),
                  ),

                  // Espaçamento entre os botões.
                  const SizedBox(height: 16.0),

                  // Botão de Cadastrar
                  OutlinedButton(
                    onPressed: () {
                      // Navega para a tela de cadastro usando a rota nomeada.
                      Navigator.of(context).pushNamed(AppRoutes.cadastro);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.white), // 4. Cor da borda
                      foregroundColor: Colors.white, // Cor do texto
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'CADASTRAR',
                    ),
                  ),

                  // Espaçamento para a versão do app
                  const SizedBox(height: 20.0),

                  // Texto da versão do aplicativo
                  Text(
                    _appVersion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
