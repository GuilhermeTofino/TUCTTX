import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      final doc = await tenantDocument('users', uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        await signOut();
        throw Exception("Acesso negado: Usuário não pertence a este aplicativo.");
      }
    } catch (e) {
      dev.log("Erro no SignIn: $e");
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage(File image, String userId) async {
    try {
      dev.log("Iniciando processo de upload para o usuário: $userId");

      // 1. Instância forçada com o bucket que você ativou
      final storage = FirebaseStorage.instanceFor(
        app: Firebase.app(),
        bucket: "tenda-white-label.firebasestorage.app", 
      );

      // 2. Referência do arquivo
      final storageRef = storage.ref().child('profiles').child(userId);

      // 3. Conversão para Bytes (Resolve erros de permissão de arquivo no iOS)
      final bytes = await image.readAsBytes();

      dev.log("Subindo bytes para o Storage...");

      // 4. Upload usando putData com metadados explícitos
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId, 'tenant': _tenantSlug},
      );

      // Aqui é onde o erro 'unauthorized' acontece se as regras não baterem
      final uploadTask = await storageRef.putData(bytes, metadata);

      // 5. Pegamos a URL pública
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      dev.log("URL de download gerada: $downloadUrl");

      // 6. Atualização no Firestore seguindo a hierarquia de Tenants
      if (_tenantSlug.isEmpty) {
        throw Exception("Slug do Tenant não identificado.");
      }

      dev.log("Atualizando Firestore: tenants/$_tenantSlug/users/$userId");

      await _firestore
          .collection('tenants')
          .doc(_tenantSlug)
          .collection('users')
          .doc(userId)
          .update({'photoUrl': downloadUrl});

      dev.log("Processo finalizado com sucesso!");
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
  }) async {
    try {
      dev.log("--- INICIANDO SIGNUP ---");

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
        return null;
      }
    });
  }
}