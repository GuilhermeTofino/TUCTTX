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

  Future<bool> updateProfilePicture(File imageFile) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Faz o upload para o Firebase Storage e pega a URL
      // _authRepository deve ter o método que criamos anteriormente
      final String newPhotoUrl = await _authRepository.uploadProfileImage(
        imageFile,
        _currentUser!.id,
      );

      // 2. Atualiza o objeto local para a foto mudar na hora na tela
      _currentUser = _currentUser!.copyWith(photoUrl: newPhotoUrl);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
