import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/base_firestore_datasource.dart';

class FirebaseUserRepository extends BaseFirestoreDataSource implements UserRepository {
  
  @override
  Future<UserModel?> getUserProfile(String uid) async {
    // Note como usamos o tenantCollection para isolar os dados
    final doc = await tenantCollection('users').doc(uid).get();
    
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    await tenantCollection('users').doc(user.id).set(user.toMap());
  }
}