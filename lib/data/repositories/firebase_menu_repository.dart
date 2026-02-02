import '../../domain/models/menu_option_model.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/base_firestore_datasource.dart';

class FirebaseMenuRepository extends BaseFirestoreDataSource
    implements MenuRepository {
  @override
  Future<List<MenuOptionModel>> getMenus(String tenantId) async {
    try {
      final snapshot = await tenantCollection('menus').orderBy('order').get();

      return snapshot.docs
          .map(
            (doc) => MenuOptionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where((menu) => menu.isEnabled)
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar menus: $e");
    }
  }
}
