import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class WelcomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  WelcomeViewModel(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  /// Verifica se já existe um usuário autenticado ao abrir o app
  void checkAuthState() {
    _isLoading = true;
    notifyListeners();

    // Escuta a primeira emissão do stream de autenticação
    _authRepository.onAuthStateChanged.first.then((user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }
}