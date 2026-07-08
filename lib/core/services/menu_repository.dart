import '../models/menu_option_model.dart';

abstract class MenuRepository {
  Future<List<MenuOptionModel>> getMenus(String tenantId);
  Future<void> saveMenu(MenuOptionModel menu);
  Future<void> deleteMenu(String menuId);
}
