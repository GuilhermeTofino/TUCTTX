import 'dart:io';
import 'package:app_tenda/domain/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String emergencyContact,
    required bool jaTirouSanto,
    bool jogoComTata,
    String? orixaFrente,
    String? orixaJunto,
    String? alergias,
    String? medicamentos,
    String? condicoesMedicas,
    String? tipoSanguineo,
    String role = 'user', 
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<String> uploadProfileImage(File image, String userId);
  Future<void> signOut();
  Stream<UserModel?> get onAuthStateChanged;

  // Método utilitário para buscar o perfil atualizado do usuário logado
  Future<UserModel?> getCurrentUserProfile(String uid);
}