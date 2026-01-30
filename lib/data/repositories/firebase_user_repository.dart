import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseUserRepository extends BaseFirestoreDataSource implements UserRepository {
  
  @override
  Future<UserModel?> getUserProfile(String uid) async {
    // Usando tenantDocument para simplificar o acesso ao perfil do usuário
    final doc = await tenantDocument('users', uid).get();
    
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    // Note que usamos o tenantDocument para garantir que o save 
    // caia sempre dentro do silo do cliente correto
    await tenantDocument('users', user.id).set(user.toMap(), SetOptions(merge: true));
  }
}