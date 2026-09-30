import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  EditProfileViewModel(
    this._authRepository,
    this._userRepository,
  ) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _currentUser = await _authRepository.getCurrentUserProfile(uid);
      }
    } catch (e) {
      debugPrint("Erro ao carregar usuário atual: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickProfilePhoto() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && _currentUser != null) {
        _isLoading = true;
        notifyListeners();

        final photoUrl = await _authRepository.uploadProfileImage(
          File(pickedFile.path),
          _currentUser!.id,
        );

        _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao selecionar foto: $e");
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? endereco,
    String? orixaFrente,
    String? orixaJunto,
    String? tipoSanguineo,
    String? alergias,
    String? medicamentos,
    String? condicoesMedicas,
    DateTime? dataNascimento,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        endereco: endereco,
        orixaFrente: orixaFrente,
        orixaJunto: orixaJunto,
        tipoSanguineo: tipoSanguineo,
        alergias: alergias,
        medicamentos: medicamentos,
        condicoesMedicas: condicoesMedicas,
        dataNascimento: dataNascimento,
      );

      await _userRepository.saveUserProfile(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      debugPrint("Erro ao atualizar perfil: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
