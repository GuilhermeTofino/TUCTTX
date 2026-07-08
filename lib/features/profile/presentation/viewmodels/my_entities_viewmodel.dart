import 'package:flutter/material.dart';
import '../../../../domain/models/entity_model.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../../../core/di/service_locator.dart';

class MyEntitiesViewModel extends ChangeNotifier {
  final UserRepository _userRepository = getIt<UserRepository>();
  final HomeViewModel _homeViewModel = getIt<HomeViewModel>();

  List<EntityModel> _entities = [];
  List<EntityModel> get entities => _entities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MyEntitiesViewModel() {
    _loadEntities();
  }

  void _loadEntities() {
    final user = _homeViewModel.currentUser;
    if (user != null && user.entities != null) {
      _entities = List<EntityModel>.from(user.entities!);
      notifyListeners();
    }
  }

  Future<void> addEntity(String type, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final user = _homeViewModel.currentUser;
    if (user == null) {
      _errorMessage = "Usuário não encontrado.";
      notifyListeners();
      return;
    }

    final newEntity = EntityModel(type: type, name: trimmedName);

    if (_entities.contains(newEntity)) {
      _errorMessage = "Entidade já adicionada.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedList = List<EntityModel>.from(_entities)..add(newEntity);
      await _userRepository.updateEntities(user.id, updatedList);

      // Atualiza o estado local
      _entities = updatedList;

      // Atualiza o usuário no HomeViewModel para refletir em toda a app e persistir na sessão
      _homeViewModel.updateCurrentUserEntities(updatedList);
    } catch (e) {
      _errorMessage = "Erro ao adicionar entidade: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeEntity(EntityModel entity) async {
    final user = _homeViewModel.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedList = List<EntityModel>.from(_entities)..remove(entity);
      await _userRepository.updateEntities(user.id, updatedList);

      _entities = updatedList;

      // Atualiza o usuário no HomeViewModel
      _homeViewModel.updateCurrentUserEntities(updatedList);
    } catch (e) {
      _errorMessage = "Erro ao remover entidade: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
