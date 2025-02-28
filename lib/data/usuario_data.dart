import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class UsuarioData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cadastra um novo usuário no Firestore
  Future<void> cadastrarUsuario(Usuario usuario) async {
    await _firestore.collection("Usuarios").doc(usuario.nome).set(usuario.toFirestore());
  }

  // Verifica se o usuário já está cadastrado
  Future<bool> usuarioJaCadastrado(String nome) async {
    final doc = await _firestore.collection("Usuarios").doc(nome).get();
    return doc.exists;
  }
}