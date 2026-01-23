import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  HomeViewModel(this._userRepository);

  // Estado da UI
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _user;
  UserModel? get user => _user;

  // Lógica de negócio para a View
  Future<void> fetchUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _userRepository.getUserProfile(uid);
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}