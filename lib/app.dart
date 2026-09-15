import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/routes/app_routes.dart';

/// Widget raiz do app: tema (baseado nas cores do tenant atual) e rotas.
/// A inicialização (Firebase, service locator, etc.) fica em main.dart.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return MaterialApp(
      title: tenant.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: tenant.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: tenant.primaryColor,
          primary: tenant.primaryColor,
          onPrimary: tenant.onPrimaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: tenant.primaryColor,
          foregroundColor: tenant.onPrimaryColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tenant.primaryColor,
            foregroundColor: tenant.onPrimaryColor,
            minimumSize: const Size(64, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
