import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  static String handleException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado.';
        case 'user-disabled':
          return 'Esta conta foi desativada.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente novamente mais tarde.';
        case 'operation-not-allowed':
          return 'Operação não permitida. Contate o suporte.';
        case 'weak-password':
          return 'A senha é muito fraca. Escolha uma senha mais forte.';
        case 'invalid-email':
          return 'O formato do e-mail é inválido.';
        case 'network-request-failed':
          return 'Sem conexão com a internet.';
        case 'requires-recent-login':
          return 'Por segurança, faça login novamente para realizar esta ação.';
        case 'credential-already-in-use':
          return 'Esta credencial já está associada a outra conta.';
        default:
          return 'Ocorreu um erro de autenticação (${e.code}).';
      }
    } else if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Sem permissão para realizar esta operação.';
        case 'unavailable':
          return 'O serviço está temporariamente indisponível.';
        case 'not-found':
          return 'O item solicitado não foi encontrado.';
        default:
          return 'Erro do sistema (${e.code}).';
      }
    }
    return e.toString().replaceAll("Exception: ", "");
  }
}
