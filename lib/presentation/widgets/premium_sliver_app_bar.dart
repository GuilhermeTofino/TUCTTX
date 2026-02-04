import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final IconData? backgroundIcon;
  final List<Widget>? actions;
  final double expandedHeight;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const PremiumSliverAppBar({
    super.key,
    required this.title,
    this.backgroundIcon,
    this.actions,
    this.expandedHeight = 120.0,
    this.showBackButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return SliverAppBar(
      expandedHeight: expandedHeight + (bottom?.preferredSize.height ?? 0),
      floating: false,
      pinned: true,
      backgroundColor: tenant.primaryColor,
      elevation: 0,
      actions: actions,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: EdgeInsets.only(
          left: showBackButton ? 56 : 24,
          bottom: (bottom?.preferredSize.height ?? 0) + 16,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tenant.primaryColor,
                    _darken(tenant.primaryColor, 0.2),
                  ],
                ),
              ),
            ),
            if (backgroundIcon != null)
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  backgroundIcon,
                  size: 140,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
