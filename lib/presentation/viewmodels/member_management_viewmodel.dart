import 'package:flutter/material.dart';
import 'package:app_tenda/domain/models/user_model.dart';
import 'package:app_tenda/domain/repositories/user_repository.dart';

class MemberManagementViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  MemberManagementViewModel(this._userRepository);

  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<UserModel> get members => _filteredMembers;
  bool get isLoading => _isLoading;

  Future<void> loadMembers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allMembers = await _userRepository.getAllUsers();
      _applyFilter();
    } catch (e) {
      debugPrint("Erro ao carregar membros: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredMembers = List.from(_allMembers);
    } else {
      _filteredMembers = _allMembers.where((user) {
        final nameMatch = user.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final emailMatch = user.email.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        return nameMatch || emailMatch;
      }).toList();
    }

    // Ordenar por nome por padrão
    _filteredMembers.sort((a, b) => a.name.compareTo(b.name));
  }
}
