import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _tenantSlug = AppConfig.instance.tenant.tenantSlug;

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final uid = result.user?.uid;
      if (uid == null) return null;

      // Busca os dados do usuário no silo do Tenant
      final doc = await _firestore
          .collection('tenants')
          .doc(_tenantSlug)
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      } else {
        await signOut();
        throw Exception("Acesso negado: Usuário não pertence a este aplicativo.");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<UserModel?> get onAuthStateChanged {
    // Escuta as mudanças do Firebase Auth e converte para UserModel
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await _firestore
          .collection('tenants')
          .doc(_tenantSlug)
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }
}