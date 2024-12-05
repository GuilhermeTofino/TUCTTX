import 'package:app_tenda/colors.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo da aplicação
            Image.asset(
              'images/logo_TUCTTX.png',
              fit: BoxFit.fitHeight,
              height: 350, // Ajusta a imagem ao tamanho do container
            ),
            // Espaçamento entre a logo e os botões
            const SizedBox(height: 150),
            // Container para os botões
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16), // Padding horizontal
              child: Column(
                children: [
                  // Botão Entrar
                  _buildElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/entrar'),
                    text: 'Entrar',
                  ),
                  const SizedBox(height: 16), // Espaçamento entre os botões
                  // Botão Cadastrar
                  _buildElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/cadastrar'),
                    text: 'Cadastrar',
                  ),
                ],
              ),
            ),
             // Espaçamento na parte inferior
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Função para construir os botões
  ElevatedButton _buildElevatedButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(45),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: kPrimaryColor),
      ),
    );
  }
}

