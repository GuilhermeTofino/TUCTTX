import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/routes/app_routes.dart';

/// Nome do app: agora é fixo (o mesmo publicado, único ícone), não vem mais
/// do tenant — quem varia por tenant é o tema/logo, carregado depois do
/// login.
const String _kAppName = 'EloApp';

/// Cor neutra usada antes do login (splash, welcome, cadastro), quando ainda
/// não sabemos a casa do usuário.
const Color _kNeutralColor = Color(0xFF3A3A3A);

/// Widget raiz do app: tema e rotas.
/// A inicialização (Firebase, service locator, etc.) fica em main.dart.
///
/// O tema reage ao [AppConfig] (um [ChangeNotifier]): antes do login ele usa
/// uma paleta neutra do EloApp; assim que o login resolve a casa do usuário
/// e chama `AppConfig.instance.setTenant(...)`, o app inteiro re-renderiza
/// com a cor/identidade daquela casa, sem precisar reiniciar.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppConfig.instance,
      builder: (context, _) {
        final tenant = AppConfig.instance.hasTenant
            ? AppConfig.instance.tenant
            : null;
        final primaryColor = tenant?.primaryColor ?? _kNeutralColor;
        final onPrimaryColor = tenant?.onPrimaryColor ?? Colors.white;

        return MaterialApp(
          title: _kAppName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              onPrimary: onPrimaryColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: onPrimaryColor,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
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
      },
    );
  }
}
