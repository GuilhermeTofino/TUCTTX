import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/core/routes/app_routes.dart';

/// Leva o usuário à tela certa quando ele toca em um push.
///
/// O destino fica guardado como "pendente" até haver sessão e a HomeView
/// pronta: login, cadastro e auto-login terminam todos na HomeView, então ela
/// é o ponto único que consome o destino (via [onHomeReady]).
class PushNavigationService {
  GlobalKey<NavigatorState>? _navigatorKey;
  PushDestination? _pending;
  bool _homeReady = false;

  /// Chamado uma vez no main, com o mesmo navigatorKey do MaterialApp.
  void attach(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Destino de um push, ou null se o tipo não navega para lugar nenhum.
  static PushDestination? parse(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'payment_receipt_pending':
        final requestId = data['requestId']?.toString();
        if (requestId == null || requestId.isEmpty) return null;
        return PushDestination(
          AppRoutes.receiptReview,
          {'requestId': requestId},
        );
      case 'payment_receipt_decision':
        return const PushDestination(AppRoutes.financialHub, {});
      default:
        return null;
    }
  }

  /// Chamado ao tocar na notificação (app aberto, em segundo plano ou encerrado).
  void handle(Map<String, dynamic> data) {
    final destination = parse(data);
    if (destination == null) return;
    _pending = destination;
    _tryNavigate();
  }

  /// A HomeView chama quando o usuário real já está carregado.
  void onHomeReady() {
    _homeReady = true;
    _tryNavigate();
  }

  void onHomeGone() {
    _homeReady = false;
  }

  void _tryNavigate() {
    final pending = _pending;
    final navigator = _navigatorKey?.currentState;
    if (pending == null) return;

    // App ainda subindo (toque com app encerrado): tenta de novo no 1º frame.
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_navigatorKey?.currentState != null) _tryNavigate();
      });
      return;
    }

    // Sem sessão: vai para o login; o destino segue pendente até a HomeView.
    if (FirebaseAuth.instance.currentUser == null) {
      navigator.pushNamed(AppRoutes.login);
      return;
    }

    // Com sessão mas Home ainda carregando: a própria Home consome depois.
    if (!_homeReady) return;

    _pending = null;
    dev.log('Push -> ${pending.route}');
    navigator.pushNamed(pending.route, arguments: pending.arguments);
  }
}

class PushDestination {
  final String route;
  final Map<String, dynamic> arguments;
  const PushDestination(this.route, this.arguments);
}
