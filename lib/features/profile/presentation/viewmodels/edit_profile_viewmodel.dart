import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
import 'package:app_tenda/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:app_tenda/features/profile/domain/models/health_data_model.dart';
import 'package:app_tenda/features/profile/domain/profile_validation.dart';

/// Dados que o usuário pode editar no próprio cadastro. Nunca inclui role,
/// status nem skills: só o admin muda (e as regras do Firestore travam).
class ProfileInput {
  final String name;
  final String phone;
  final DateTime? dataNascimento;
  final String? endereco;
  final String? orixaFrente;
  final String? orixaJunto;
  final HealthData health;

  const ProfileInput({
    required this.name,
    required this.phone,
    this.dataNascimento,
    this.endereco,
    this.orixaFrente,
    this.orixaJunto,
    this.health = const HealthData(),
  });
}

class EditProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ImagePicker _imagePicker = ImagePicker();

  EditProfileViewModel(this._authRepository, this._userRepository);

  UserModel? _user;
  HealthData _health = const HealthData();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _loadError;
  String? _localPhotoPath;

  UserModel? get user => _user;
  HealthData get health => _health;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get loadError => _loadError;

  /// Foto escolhida agora (preview imediato, antes de a URL nova voltar).
  String? get localPhotoPath => _localPhotoPath;

  /// Carrega o perfil E os dados de saúde antes de o formulário existir, para
  /// nunca abrir vazio: salvar um formulário vazio apagaria o cadastro.
  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('Entre na sua conta para editar o cadastro.');

      final user = await _userRepository.getUserProfile(uid);
      if (user == null) throw StateError('Cadastro não encontrado.');
      _user = user;

      // Saúde: subcoleção privada; cai nos campos antigos do documento enquanto
      // ele não foi migrado (ver scripts/admin/migrate-private-health.js).
      _health = await _userRepository.getHealth(uid) ??
          HealthData(
            alergias: user.alergias,
            medicamentos: user.medicamentos,
            condicoesMedicas: user.condicoesMedicas,
            tipoSanguineo: user.tipoSanguineo,
          );
    } on StateError catch (e) {
      _loadError = e.message;
    } catch (e) {
      debugPrint('Erro ao carregar cadastro: $e');
      _loadError = 'Não foi possível carregar seu cadastro. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Escolhe uma foto da galeria e envia. Retorna a mensagem de erro, ou null.
  Future<String?> pickAndUploadPhoto() async {
    final current = _user;
    if (current == null) return 'Cadastro ainda não carregado.';

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    _localPhotoPath = picked.path;
    _isUploadingPhoto = true;
    notifyListeners();
    try {
      // O repositório de auth envia o arquivo e já grava photoUrl no documento.
      final url = await _authRepository.uploadProfileImage(File(picked.path), current.id);
      _user = current.copyWith(photoUrl: url);
      getIt<HomeViewModel>().updateCurrentUser(
        (getIt<HomeViewModel>().currentUser ?? current).copyWith(photoUrl: url),
      );
      return null;
    } catch (e) {
      debugPrint('Erro ao enviar foto: $e');
      _localPhotoPath = null;
      return 'Não foi possível enviar a foto. Tente novamente.';
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  /// Valida e grava. Só toca nos campos pessoais (nunca role/status/skills) e
  /// grava a saúde na subcoleção privada. Retorna a mensagem de erro, ou null.
  Future<String?> save(ProfileInput input) async {
    final current = _user;
    if (current == null) return 'Cadastro ainda não carregado.';

    final error = ProfileValidation.name(input.name) ??
        ProfileValidation.phone(input.phone) ??
        ProfileValidation.birthDate(input.dataNascimento);
    if (error != null) return error;

    _isSaving = true;
    notifyListeners();
    try {
      final personal = <String, dynamic>{
        'name': input.name.trim(),
        'phone': input.phone.trim(),
        'endereco': ProfileValidation.optional(input.endereco),
        'orixaFrente': ProfileValidation.optional(input.orixaFrente),
        'orixaJunto': ProfileValidation.optional(input.orixaJunto),
        'dataNascimento': input.dataNascimento?.toIso8601String(),
      };
      await _userRepository.updatePersonalFields(current.id, personal);

      final health = input.health.cleaned();
      await _userRepository.saveHealth(current.id, health);

      // Relê o perfil gravado: o copyWith do modelo mantém o valor antigo quando
      // recebe null, então apagar um campo não apareceria na tela.
      final fresh = await _userRepository.getUserProfile(current.id);
      _user = fresh ?? current;
      _health = health;

      // Atualiza o cartão da Home sem reler tudo.
      final home = getIt<HomeViewModel>();
      if (fresh != null) home.updateCurrentUser(fresh);
      home.updateOwnHealth(health);
      return null;
    } catch (e) {
      debugPrint('Erro ao salvar cadastro: $e');
      return 'Não foi possível salvar. Tente novamente.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
