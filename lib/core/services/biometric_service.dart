import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:developer' as dev;

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Verifica se o aparelho tem biometria configurada (FaceID ou Digital)
  Future<bool> canUseBiometrics() async {
    final bool canCheck = await _localAuth.canCheckBiometrics;
    final bool isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  // Tenta autenticar o usuário
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Autentique-se para entrar no app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      dev.log("Erro na autenticação biométrica: $e");
      return false;
    }
  }

  // Salva as credenciais após o primeiro login manual com sucesso
  Future<void> saveCredentials(String email, String password, String tenant) async {
    await _secureStorage.write(key: 'auth_email_$tenant', value: email);
    await _secureStorage.write(key: 'auth_password_$tenant', value: password);
    dev.log("Credenciais salvas com segurança para o tenant: $tenant");
  }

  // Recupera as credenciais
  Future<Map<String, String?>> getSavedCredentials(String tenant) async {
    String? email = await _secureStorage.read(key: 'auth_email_$tenant');
    String? password = await _secureStorage.read(key: 'auth_password_$tenant');
    return {'email': email, 'password': password};
  }

  // Limpa as credenciais (ex: no Logout)
  Future<void> clearCredentials(String tenant) async {
    await _secureStorage.delete(key: 'auth_email_$tenant');
    await _secureStorage.delete(key: 'auth_password_$tenant');
  }
}