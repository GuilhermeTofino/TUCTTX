import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Adicione este formatter para formatar corretamente enquanto o usuário digita
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat("#,##0.00", "pt_BR");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Remove tudo que não for número
    if (newText.isEmpty) return newValue.copyWith(text: "");

    double value = double.parse(newText) / 100;
    String formattedValue = formatter.format(value);

    return newValue.copyWith(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}