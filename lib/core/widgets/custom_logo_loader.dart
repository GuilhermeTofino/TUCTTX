import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class CustomLogoLoader extends StatelessWidget {
  final double size;
  final double logoSize;

  const CustomLogoLoader({
    super.key,
    this.size = 80.0,
    this.logoSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // O Indicador de progresso circular externo
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(tenant.primaryColor),
              strokeWidth: 3.0, // Espessura da linha
              backgroundColor: tenant.primaryColor.withOpacity(0.1),
            ),
          ),
          // O Logo do Tenant no centro
          ClipOval(
            child: Image.asset(
              tenant.logoPath,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              // Caso o logo falhe ou não exista, mostra um ícone genérico
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.church, // Ou outro ícone que represente a casa
                color: tenant.primaryColor,
                size: logoSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}