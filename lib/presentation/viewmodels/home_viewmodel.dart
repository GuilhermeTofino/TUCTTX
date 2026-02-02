import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    // O onAuthStateChanged já nos dá o UserModel completo
    _authRepository.onAuthStateChanged.listen((user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
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
