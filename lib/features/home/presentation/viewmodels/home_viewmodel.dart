import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/profile/domain/models/entity_model.dart';
import 'package:app_tenda/core/services/menu_option_model.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_tenda/core/services/menu_repository.dart';
import 'package:app_tenda/core/services/notification_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  final MenuRepository _menuRepository = getIt<MenuRepository>();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  List<MenuOptionModel> _menus = [];
  List<MenuOptionModel> get menus => _menus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> _mockDevUser() async {
    _currentUser = UserModel(
      id: 'mock_user_id',
      name: 'Desenvolvedor Mock',
      email: 'dev@tucttx.com',
      role: 'admin',
      tenantSlug: 'tucttx',
      phone: '11999999999',
      emergencyContact: '11999999998',
      jaTirouSanto: true,
      orixaFrente: 'Oxalá',
      orixaJunto: 'Iemanjá',
    );
    _isLoading = false;
    notifyListeners();
    await loadMenus('tucttx');
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    // Se estiver em modo de desenvolvimento (DEV), adicionamos um timer de segurança para disparar o mock
    // caso a escuta de autenticação do Firebase retorne null (sem usuário logado)
    _authRepository.onAuthStateChanged.listen((user) {
      if (user != null) {
        _currentUser = user;
        getIt<NotificationService>().saveDeviceToken(user.id);
        getIt<NotificationService>().subscribeToTenantTopics(
          user.tenantSlug,
          const String.fromEnvironment('ENV', defaultValue: 'dev'),
        );
        loadMenus(user.tenantSlug);
      } else {
        final isDev = const String.fromEnvironment('ENV', defaultValue: 'dev') == 'dev';
        if (isDev) {
          _mockDevUser();
        } else {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> loadMenus(String tenantId) async {
    try {
      final rawMenus = await _menuRepository.getMenus(tenantId);
      // Filter out 'health' menu as requested by user
      _menus = rawMenus.where((m) => m.action != 'internal:health').toList();

      // INJECTION: Add House Entities Menu manually for ALL users
      _menus.add(
        MenuOptionModel(
          id: 'house_entities',
          title: 'Entidades da Casa',
          icon:
              'people', // Reusing 'people' icon which maps to Icons.people_alt_rounded
          color: '#673AB7', // Deep Purple
          action: 'route:/admin-house-entities',
          order: 999,
        ),
      );
    } catch (e) {
      debugPrint("Erro ao carregar menus: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // Na HomeViewModel
  Future<bool> updateProfilePicture(File file) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Reutiliza a lógica de upload que criamos no Repository
      final String newUrl = await _authRepository.uploadProfileImage(
        file,
        _currentUser!.id,
      );

      // Atualiza o estado local para refletir na UI imediatamente
      _currentUser = _currentUser!.copyWith(photoUrl: newUrl);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.deleteAccount();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Método adicionado para atualizar as entidades localmente e refletir na UI
  void updateCurrentUserEntities(List<EntityModel> newEntities) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(entities: newEntities);
      notifyListeners();
    }
  }
}
