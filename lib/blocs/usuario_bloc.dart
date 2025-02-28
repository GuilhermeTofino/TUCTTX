import '../models/usuario_model.dart';
import '../data/usuario_data.dart';

class UsuarioBloc {
  final UsuarioData _usuarioData = UsuarioData();

  Future<String?> cadastrarUsuario(Usuario usuario) async {
    bool existe = await _usuarioData.usuarioJaCadastrado(usuario.nome);
    if (existe) {
      return "Usuário já cadastrado!";
    }

    await _usuarioData.cadastrarUsuario(usuario);
    return null;
  }
}