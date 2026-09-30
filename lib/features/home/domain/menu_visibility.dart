import 'package:app_tenda/core/services/menu_option_model.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';

/// Ações de menu que o consulente pode abrir: só o calendário. O resto (finanças,
/// estudos, cambones, entidades da casa) é de membros; as regras já barram os dados.
const Set<String> visitorMenuActions = {'route:/calendar'};

/// Menus que aparecem na Home para [user]. Membros e admins veem todos.
List<MenuOptionModel> menusFor(UserModel user, List<MenuOptionModel> menus) {
  if (user.isMember) return List.of(menus);
  return menus.where((m) => visitorMenuActions.contains(m.action)).toList();
}
