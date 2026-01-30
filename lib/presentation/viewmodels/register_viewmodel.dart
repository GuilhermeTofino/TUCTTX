import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  RegisterViewModel(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> registerUser({
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signUp(
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        password: data['password'],
        emergencyContact: data['emergencyContact'],
        jaTirouSanto: data['jaTirouSanto'],
        jogoComTata: data['jogoComTata'] ?? false,
        orixaFrente: data['orixaFrente'],
        orixaJunto: data['orixaJunto'],
        alergias: data['alergias'],
        medicamentos: data['medicamentos'],
        condicoesMedicas: data['condicoesMedicas'],
        tipoSanguineo: data['tipoSanguineo'],
      );
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Novo método para suportar a tela de Login
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signIn(email, password);
      
      _isLoading = false;
      if (user == null) {
        _errorMessage = "E-mail ou senha incorretos.";
      }
      
      notifyListeners();
      return user != null; // Retorna true se o usuário for encontrado
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Método auxiliar para deslogar (útil para o botão Sair da Home)
  Future<void> signOut() async {
    await _authRepository.signOut();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
  _isLoading = true;
  notifyListeners();
  try {
    await _authRepository.sendPasswordResetEmail(email);
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