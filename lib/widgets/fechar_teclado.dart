import 'package:flutter/material.dart';

class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Captura toques em qualquer lugar
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus(); // Fecha o teclado
      },
      child: child,
    );
  }
}
