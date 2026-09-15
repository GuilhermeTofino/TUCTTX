import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as dev;
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/config/tenant_repository.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';
import 'package:app_tenda/core/utils/auth_exception_handler.dart';

class FirebaseAuthRepository extends BaseFirestoreDataSource
    implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TenantRepository _tenantRepository = TenantRepository();

  // Continua útil como atalho para código já rodando pós-login (upload de
  // foto, etc). NUNCA usar em field initializer: o tenant só existe depois
  // que o login/resolveTenantForUser resolve a casa.
  String get _tenantSlug => AppConfig.instance.tenant.tenantSlug;

  /// Descobre a casa do usuário logado e carrega a config dela no
  /// [AppConfig], para então poder acessar as coleções tenant-scoped
  /// (users, events, etc). É o primeiro passo depois de qualquer login bem
  /// sucedido, e também ao restaurar sessão (onAuthStateChanged).
  Future<void> _resolveTenantForUser(String uid) async {
    final indexDoc = await userTenantIndexDocument(uid).get();
    final data = indexDoc.data() as Map<String, dynamic>?;
    final tenantSlug = data?['tenantSlug'] as String?;

    if (!indexDoc.exists || tenantSlug == null) {
      throw Exception("Acesso negado: Usuário não pertence a nenhuma casa.");
    }

    final tenant = await _tenantRepository.fetchTenant(tenantSlug);
    AppConfig.instance.setTenant(tenant);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) return null;

      // Antes de tocar em qualquer coleção tenant-scoped, precisamos saber
      // qual é a casa deste usuário.
      await _resolveTenantForUser(uid);

      // Busca o perfil completo incluindo o campo 'role'
      final doc = await tenantDocument('users', uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        await signOut();
        throw Exception(
          "Acesso negado: Usuário não pertence a este aplicativo.",
        );
      }
    } catch (e) {
      dev.log("Erro no SignIn: $e");
      AppConfig.instance.clearTenant();
      throw Exception(AuthExceptionHandler.handleException(e));
    }
  }

  @override
  Future<UserModel?> getCurrentUserProfile(String uid) async {
    try {
      final doc = await tenantDocument('users', uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      dev.log("Erro ao buscar perfil atual: $e");
      return null;
    }
  }

  @override
  Future<String> uploadProfileImage(File image, String userId) async {
    try {
      dev.log("Iniciando processo de upload para o usuário: $userId");

      final storage = FirebaseStorage.instanceFor(
        app: Firebase.app(),
        bucket: "tenda-white-label.firebasestorage.app",
      );

      final env = AppConfig.instance.environment == AppEnvironment.dev
          ? 'dev'
          : 'prod';

      final storageRef = storage
          .ref()
          .child('environments')
          .child(env)
          .child('tenants')
          .child(_tenantSlug)
          .child('profiles')
          .child(userId);
      final bytes = await image.readAsBytes();

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId, 'tenant': _tenantSlug},
      );

      final uploadTask = await storageRef.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (_tenantSlug.isEmpty) {
        throw Exception("Slug do Tenant não identificado.");
      }

      await tenantDocument('users', userId).update({'photoUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      dev.log("FALHA NO REPOSITÓRIO: $e");
      rethrow;
    }
  }

  @override
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
    bool jogoComTata = false,
    String? orixaFrente,
    String? orixaJunto,
    String? alergias,
    String? medicamentos,
    String? condicoesMedicas,
    String? tipoSanguineo,
    String role = 'user', // Suporte para definição de cargo no cadastro
  }) async {
    try {
      final joiningExisting = newTenant == null;

      if (name.trim().isEmpty ||
          email.trim().isEmpty ||
          phone.trim().isEmpty ||
          emergencyContact.trim().isEmpty ||
          (joiningExisting &&
              (inviteCode == null || inviteCode.trim().isEmpty))) {
        throw Exception("Por favor, preencha todos os campos obrigatórios.");
      }

      if (password.length < 6) {
        throw Exception("A senha deve ter pelo menos 6 caracteres.");
      }

      dev.log("--- INICIANDO SIGNUP VALIDADO ---");

      // Se está entrando numa casa existente, resolve o código de convite
      // ANTES de criar o usuário, pra falhar cedo (código inválido) em vez
      // de deixar o cadastro pela metade. Se está cadastrando uma casa
      // nova, isso só é possível depois de termos o uid (vira o
      // responsavelUid da casa), então acontece adiante.
      String? slugFromInviteCode;
      if (joiningExisting) {
        slugFromInviteCode = await _tenantRepository.resolveSlugByInviteCode(
          inviteCode!,
        );
        final tenant = await _tenantRepository.fetchTenant(
          slugFromInviteCode,
        );
        AppConfig.instance.setTenant(tenant);
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) return null;

      // Resolve o slug final e o role: quem cadastra uma casa nova vira
      // automaticamente o admin/dirigente dela.
      String resolvedSlug;
      String resolvedRole;

      if (joiningExisting) {
        resolvedSlug = slugFromInviteCode!;
        resolvedRole = role;
      } else {
        resolvedSlug = await _tenantRepository.createTenant(
          newTenant,
          responsavelUid: uid,
        );
        if (tenantLogo != null) {
          await _tenantRepository.uploadTenantLogo(tenantLogo, resolvedSlug);
        }
        final tenant = await _tenantRepository.fetchTenant(resolvedSlug);
        AppConfig.instance.setTenant(tenant);
        resolvedRole = 'admin';
      }

      // Registra o vínculo uid -> casa, usado pelo login pra descobrir onde
      // buscar o perfil desse usuário.
      await userTenantIndexDocument(uid).set({'tenantSlug': resolvedSlug});

      final newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        emergencyContact: emergencyContact,
        tenantSlug: resolvedSlug,
        jaTirouSanto: jaTirouSanto,
        jogoComTata: jogoComTata,
        orixaFrente: orixaFrente,
        orixaJunto: orixaJunto,
        alergias: alergias,
        medicamentos: medicamentos,
        condicoesMedicas: condicoesMedicas,
        tipoSanguineo: tipoSanguineo,
        createdAt: DateTime.now(),
        role: resolvedRole,
      );

      await tenantDocument('users', uid).set(newUser.toMap());

      dev.log("--- CADASTRO FINALIZADO ---");
      return newUser;
    } catch (e) {
      dev.log("ERRO NO SIGNUP: $e");
      AppConfig.instance.clearTenant();
      throw Exception(AuthExceptionHandler.handleException(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      dev.log("Erro ao enviar reset de senha: $e");
      throw Exception(AuthExceptionHandler.handleException(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    AppConfig.instance.clearTenant();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");

    try {
      dev.log("Iniciando exclusão da conta do usuário: ${user.uid}");

      // 1. Deleta o documento do usuário no Firestore (Tenant)
      await tenantDocument('users', user.uid).delete();

      // 2. Deleta o usuário do Firebase Auth
      await user.delete();

      dev.log("Conta excluída com sucesso.");
    } catch (e) {
      dev.log("Erro ao excluir conta: $e");
      throw Exception(AuthExceptionHandler.handleException(e));
    }
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        AppConfig.instance.clearTenant();
        return null;
      }
      try {
        // Ao reabrir o app com uma sessão já ativa, o AppConfig ainda não
        // tem a casa carregada (isso não sobrevive ao restart) — resolve de
        // novo antes de tentar ler o perfil do usuário.
        if (!AppConfig.instance.hasTenant) {
          await _resolveTenantForUser(firebaseUser.uid);
        }

        final doc = await tenantDocument('users', firebaseUser.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } catch (e) {
        dev.log("Erro no stream de auth (esperado se não autenticado): $e");
        return null;
      }
    });
  }
}
