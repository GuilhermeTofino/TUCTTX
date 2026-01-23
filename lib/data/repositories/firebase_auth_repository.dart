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
      // 1. Tenta o login no Firebase Auth
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = result.user?.uid;

      if (uid != null) {
        // 2. VALIDAÇÃO CRÍTICA: O usuário existe na subcoleção DESTE tenant?
        final doc = await _firestore
            .collection('tenants')
            .doc(_tenantSlug)
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data()!);
        } else {
          // Se o usuário existe no Auth mas não neste tenant, deslogamos ele
          await signOut();
          throw Exception("Usuário não autorizado para este aplicativo.");
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<UserModel?> get onAuthStateChanged {
    // Implementação simplificada para o exemplo
    return _auth.authStateChanges().map((user) => null); 
  }
}