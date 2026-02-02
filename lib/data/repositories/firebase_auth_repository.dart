import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as dev;
import '../../core/config/app_config.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseAuthRepository extends BaseFirestoreDataSource
    implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _tenantSlug = AppConfig.instance.tenant.tenantSlug;

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) return null;

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
      rethrow;
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
      if (name.trim().isEmpty ||
          email.trim().isEmpty ||
          phone.trim().isEmpty ||
          emergencyContact.trim().isEmpty) {
        throw Exception("Por favor, preencha todos os campos obrigatórios.");
      }

      if (password.length < 6) {
        throw Exception("A senha deve ter pelo menos 6 caracteres.");
      }

      dev.log("--- INICIANDO SIGNUP VALIDADO ---");

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) return null;

      final newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        emergencyContact: emergencyContact,
        tenantSlug: _tenantSlug,
        jaTirouSanto: jaTirouSanto,
        jogoComTata: jogoComTata,
        orixaFrente: orixaFrente,
        orixaJunto: orixaJunto,
        alergias: alergias,
        medicamentos: medicamentos,
        condicoesMedicas: condicoesMedicas,
        tipoSanguineo: tipoSanguineo,
        createdAt: DateTime.now(),
        role: role, // Atribui o role (padrão 'user')
      );

      await tenantDocument('users', uid).set(newUser.toMap());

      dev.log("--- CADASTRO FINALIZADO ---");
      return newUser;
    } catch (e) {
      dev.log("ERRO NO SIGNUP: $e");
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc = await tenantDocument('users', firebaseUser.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } catch (e) {
        dev.log("Erro no stream de auth: $e");
        return null;
      }
    });
  }
}
