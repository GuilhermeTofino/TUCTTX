import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/menu_option_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../core/services/notification_service.dart';

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

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    _authRepository.onAuthStateChanged.listen((user) {
      _currentUser = user;
      if (user != null) {
        // Captura e salva o token de notificação deste dispositivo
        getIt<NotificationService>().saveDeviceToken(user.id);

        // Inscreve o usuário nos tópicos do terreiro (ex: tucttx_dev_all)
        getIt<NotificationService>().subscribeToTenantTopics(
          user.tenantSlug,
          const String.fromEnvironment('ENV', defaultValue: 'dev'),
        );

        // Assim que tivermos o usuário (e o tenant slug dele), carregamos os menus
        loadMenus(user.tenantSlug);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadMenus(String tenantId) async {
    try {
      _menus = await _menuRepository.getMenus(tenantId);
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
}
