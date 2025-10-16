import 'package:app_tenda/widgets/gradient_container.dart';
import 'package:flutter/material.dart';

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Adicionamos uma AppBar para permitir a navegação de volta.
      appBar: AppBar(
        backgroundColor: Colors
            .transparent, // Deixa a AppBar transparente para ver o gradiente.
        elevation: 0, // Remove a sombra.
        foregroundColor:
            Colors.white, // Garante que o ícone de voltar seja branco.
      ),
      // Estendemos o corpo para trás da AppBar para que o gradiente preencha tudo.
      extendBodyBehindAppBar: true,
      body: const GradientContainer(
        child: SafeArea(
          child: Center(
            child: Text(
              'Tela de Cadastro',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}
