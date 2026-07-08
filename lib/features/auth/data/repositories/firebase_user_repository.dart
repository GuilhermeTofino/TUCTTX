import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/entity_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseUserRepository extends BaseFirestoreDataSource
    implements UserRepository {
  @override
  Future<UserModel?> getUserProfile(String uid) async {
    // Busca o documento dentro da subcoleção 'users' do tenant atual
    final doc = await tenantDocument('users', uid).get();

    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    // Salva ou atualiza os dados, garantindo a persistência do campo 'role'
    await tenantDocument(
      'users',
      user.id,
    ).set(user.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    // Busca todos os usuários pertencentes ao silo deste tenant
    final querySnapshot = await tenantCollection('users').get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateAmaciDates(
    String uid,
    DateTime? lastAmaci,
    DateTime? nextAmaci,
  ) async {
    await tenantDocument('users', uid).set({
      'lastAmaciDate': lastAmaci?.toIso8601String(),
      'nextAmaciDate': nextAmaci?.toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateEntities(String uid, List<EntityModel> entities) async {
    await tenantDocument('users', uid).set({
      'entities': entities.map((e) => e.toMap()).toList(),
    }, SetOptions(merge: true));
  }
}
