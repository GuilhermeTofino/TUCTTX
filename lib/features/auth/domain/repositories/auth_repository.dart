import 'dart:io';
import 'package:app_tenda/core/config/tenant_repository.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);

  /// Cadastra um novo usuário. Informe exatamente um dos dois:
  /// - [inviteCode]: entra numa casa já existente, como membro comum. É o
  ///   código que o dirigente daquela casa repassou (não uma lista pública
  ///   de casas), pra evitar entrar na casa errada.
  /// - [newTenant]: cadastra uma casa nova (o dirigente/responsável
  ///   preenche os dados dela) e o usuário vira automaticamente o admin
  ///   dessa casa.
  Future<UserModel?> signUp({
    String? inviteCode,
    NewTenantInput? newTenant,
    File? tenantLogo,
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
  Future<void> deleteAccount();
  Stream<UserModel?> get onAuthStateChanged;

  // Método utilitário para buscar o perfil atualizado do usuário logado
  Future<UserModel?> getCurrentUserProfile(String uid);
}
