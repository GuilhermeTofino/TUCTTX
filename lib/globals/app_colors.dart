import 'package:flutter/material.dart';

/// Uma classe para armazenar as cores principais da identidade visual do app.
/// Isso centraliza as cores, facilitando a manutenção e garantindo consistência.
class AppColors {
  // Esta classe não deve ser instanciada.
  AppColors._();

  // Cores principais (substitua pelos valores hexadecimais da sua marca)
  static const Color primary = Color(0xFF72150E); // Ex: Roxo
  static const Color secondary = Color(0xff9F0000); // Ex: Ciano
  static const Color accent = Color(0xFF03DAC6);

  // Cores de texto
  static const Color textPrimary = Color(0xFF212121); // Preto mais suave
  static const Color textSecondary = Color(0xFF757575); // Cinza
  static const Color textOnPrimary = Colors.white; // Texto sobre a cor primária

  // Outras cores
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color border = Color(0xFFE0E0E0); // Para bordas de botões, etc.
}
