import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    // Ajusta as cores dos ícones da barra de status (bateria, hora)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Área da Logo (Topo)
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white.withOpacity(0.9)],
                  ),
                ),
                child: Center(
                  child: TweenAnimationBuilder(
                    duration: const Duration(seconds: 1),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(scale: value, child: child),
                      );
                    },
                    child: Image.asset(
                      'assets/tenants/${tenant.tenantSlug}/logo.png',
                      width: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.fitWidth,
                      // Fallback caso a imagem não exista ainda
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.store_rounded,
                            size: 140,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Card de Ações (Base)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: tenant.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Seja bem-vindo a",
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tenant.tenantName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botão Entrar (Sólido)
                  _buildMainButton(
                    context,
                    label: "ACESSAR CONTA",
                    onPressed: () {
                      // Navigator.pushNamed(context, '/login');
                    },
                    color: Colors.white,
                    textColor: tenant.primaryColor,
                  ),

                  const SizedBox(height: 15),

                  // Botão Cadastrar (Transparente/Outlined)
                  _buildSecondaryButton(
                    context,
                    label: "Criar nova conta",
                    onPressed: () {
                      // Navigator.pushNamed(context, '/register');
                    },
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: textColor.withOpacity(0.3), width: 2),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
