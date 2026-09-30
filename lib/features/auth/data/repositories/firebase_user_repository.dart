import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tenda/features/profile/domain/models/entity_model.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';
import 'package:app_tenda/features/profile/domain/models/health_data_model.dart';

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

  @override
  Future<void> updatePersonalFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    final invalid = fields.keys.where(
      (k) => !UserRepository.personalFields.contains(k),
    );
    if (invalid.isNotEmpty) {
      throw ArgumentError('Campos não editáveis pelo usuário: ${invalid.join(', ')}');
    }
    if (fields.isEmpty) return;
    await tenantDocument('users', uid).update(fields);
  }

  DocumentReference _healthRef(String uid) =>
      tenantDocument('users', uid).collection('private').doc('health');

  @override
  Future<HealthData?> getHealth(String uid) async {
    final doc = await _healthRef(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return HealthData.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> saveHealth(String uid, HealthData health) async {
    await _healthRef(uid).set({
      ...health.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> requestApproval(String uid) async {
    await tenantDocument('users', uid).update({'status': 'pending_approval'});
  }
}
