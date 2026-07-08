import 'package:flutter/material.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  // Variável para armazenar o usuário atual e seu perfil completo
  UserModel? _currentUser;

  RegisterViewModel(this._authRepository) {
    // Escuta o Stream de autenticação para manter o _currentUser atualizado
    _authRepository.onAuthStateChanged.listen((user) {
      _currentUser = user;
      if (user != null) {
        // _initializeNotifications(user);
      }
      notifyListeners();
    });
  }

  // void _initializeNotifications(UserModel user) {
  //   // Pegamos o serviço do getIt e iniciamos o processo
  //   getIt<NotificationService>().initialize(user);
  // }

  // Getter que resolve o erro 'isAdmin' na sua CalendarView
  bool get isAdmin => _currentUser?.role == 'admin';

  // Getter para acessar os dados do usuário se necessário
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> registerUser({required Map<String, dynamic> data}) async {
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
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signIn(email, password);

      _isLoading = false;
      if (user == null) {
        _errorMessage = "E-mail ou senha incorretos.";
      } else {
        _currentUser = user; // Garante a atualização imediata no login
      }

      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _currentUser = null;
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
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }
}
