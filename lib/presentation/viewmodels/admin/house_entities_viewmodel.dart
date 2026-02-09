import 'package:flutter/foundation.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../domain/models/entity_model.dart';
import '../../../../domain/repositories/user_repository.dart';

class HouseEntityItem {
  final EntityModel entity;
  final String userName;
  final String userId;

  HouseEntityItem({
    required this.entity,
    required this.userName,
    required this.userId,
  });
}

class HouseEntitiesViewModel extends ChangeNotifier {
  final UserRepository _userRepository = getIt<UserRepository>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, List<HouseEntityItem>> _allGroupedEntities = {};
  Map<String, List<HouseEntityItem>> _filteredGroupedEntities = {};
  Map<String, List<HouseEntityItem>> get groupedEntities =>
      _filteredGroupedEntities;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  Future<void> loadHouseEntities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final users = await _userRepository.getAllUsers();
      final Map<String, List<HouseEntityItem>> groups = {};

      for (var user in users) {
        if (user.entities != null) {
          for (var entity in user.entities!) {
            final item = HouseEntityItem(
              entity: entity,
              userName: user.name,
              userId: user.id,
            );

            // Normaliza o tipo (ex: "Exu" -> "Exu")
            // Se o tipo for vazio, usa "Outros"
            final type = entity.type.isNotEmpty ? entity.type : 'Outros';

            if (!groups.containsKey(type)) {
              groups[type] = [];
            }
            groups[type]!.add(item);
          }
        }
      }

      // Ordenar as chaves (Tipos) se necessário, ou manter a ordem de inserção
      // Ordenar os itens dentro de cada grupo por nome da entidade
      for (var key in groups.keys) {
        groups[key]!.sort((a, b) => a.entity.name.compareTo(b.entity.name));
      }

      _allGroupedEntities = groups;
      _applyFilter();
    } catch (e) {
      _errorMessage = "Erro ao carregar entidades da casa: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredGroupedEntities = Map.from(_allGroupedEntities);
      return;
    }

    final Map<String, List<HouseEntityItem>> filtered = {};

    _allGroupedEntities.forEach((type, items) {
      final matches = items.where((item) {
        final entityName = item.entity.name.toLowerCase();
        final userName = item.userName.toLowerCase();
        return entityName.contains(_searchQuery) ||
            userName.contains(_searchQuery);
      }).toList();

      if (matches.isNotEmpty) {
        filtered[type] = matches;
      }
    });

    _filteredGroupedEntities = filtered;
  }
}
