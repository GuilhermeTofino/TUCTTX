import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Conecta o app ao Firebase Emulator Suite (Auth, Firestore, Storage) em vez do
/// projeto real. Serve para testar regras e telas novas sem tocar em produção:
/// dev e prod compartilham o mesmo projeto Firebase, então "dev" no Firebase real
/// NÃO é isolado.
///
/// Liga só com `--dart-define=USE_EMULATOR=true`. Em Android emulator o host é
/// 10.0.2.2 (padrão); iOS simulator usa `--dart-define=EMULATOR_HOST=localhost`; num
/// aparelho físico, o IP do Mac na rede (`EMULATOR_HOST=192.168.x.x`).
///
/// Fecha por segurança: se algo não apontar para o emulador, o app NÃO abre, em vez
/// de gravar em produção achando que está no emulador.
class EmulatorSetup {
  static const bool enabled = bool.fromEnvironment('USE_EMULATOR');
  static const String host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int storagePort = 9199;

  /// Bucket que o app usa em `FirebaseStorage.instanceFor` (foto de perfil).
  static const String _profileBucket = 'tenda-white-label.firebasestorage.app';

  /// Chamar DEPOIS de configurar `FirebaseFirestore.settings`: essa atribuição
  /// substitui o objeto de configurações inteiro e desfaria o host do emulador.
  static Future<void> connectIfEnabled() async {
    if (!enabled) return;
    if (kReleaseMode) {
      throw StateError('USE_EMULATOR não pode ser usado em build de release.');
    }

    // Sem cache em disco: ele poderia mostrar documentos do projeto real
    // guardados por uma execução anterior.
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(persistenceEnabled: false);
    firestore.useFirestoreEmulator(host, firestorePort);

    FirebaseAuth.instance.useAuthEmulator(host, authPort);

    // Duas instâncias de Storage no app (a padrão e a do bucket da foto de perfil).
    final defaultStorage = FirebaseStorage.instance;
    defaultStorage.useStorageEmulator(host, storagePort);
    final profileStorage = FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: _profileBucket,
    );
    if (!identical(defaultStorage, profileStorage)) {
      profileStorage.useStorageEmulator(host, storagePort);
    }

    // Trava: confirma que o Firestore realmente está no emulador.
    final actualHost = firestore.settings.host;
    if (actualHost != '$host:$firestorePort') {
      throw StateError(
        'O Firestore NÃO está apontando para o emulador (host: $actualHost). '
        'Abortando para não gravar em produção.',
      );
    }

    // Uma sessão guardada do projeto real não vale no emulador: sai dela.
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      try {
        await current.getIdToken(true);
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }
    }

    debugPrint('*** EMULADORES ATIVOS ($host) — nada disto toca a produção ***');
  }
}
