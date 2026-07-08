import 'package:app_tenda/core/services/menu_option_model.dart';
import 'package:app_tenda/core/services/menu_repository.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';

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

  @override
  Future<void> saveMenu(MenuOptionModel menu) async {
    try {
      await tenantDocument('menus', menu.id).set(menu.toMap());
    } catch (e) {
      throw Exception("Erro ao salvar menu: $e");
    }
  }

  @override
  Future<void> deleteMenu(String menuId) async {
    try {
      await tenantDocument('menus', menuId).delete();
    } catch (e) {
      throw Exception("Erro ao excluir menu: $e");
    }
  }
}
