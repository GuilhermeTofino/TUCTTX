import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../domain/models/announcement_model.dart';
import '../../../domain/repositories/announcement_repository.dart';
import '../../../core/di/service_locator.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementRepository _repository = getIt<AnnouncementRepository>();

  StreamSubscription<List<AnnouncementModel>>? _subscription;
  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime? _lastSeenAt;
  bool _hasUnread = false;
  bool get hasUnread => _hasUnread;

  Future<void> loadLastSeen(String tenantId) async {
    final stored = await _storage.read(
      key: 'announcements_last_seen_$tenantId',
    );
    if (stored != null) {
      _lastSeenAt = DateTime.parse(stored);
    }
    notifyListeners();
  }

  void checkUnread(List<AnnouncementModel> announcements) {
    if (_lastSeenAt == null) {
      _hasUnread = announcements.isNotEmpty;
    } else {
      _hasUnread = announcements.any((a) => a.createdAt.isAfter(_lastSeenAt!));
    }
    notifyListeners();
  }

  Future<void> markAsRead(String tenantId) async {
    _lastSeenAt = DateTime.now();
    await _storage.write(
      key: 'announcements_last_seen_$tenantId',
      value: _lastSeenAt!.toIso8601String(),
    );
    _hasUnread = false;
    notifyListeners();
  }

  void listenToAnnouncements(String tenantId) {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription?.cancel();
      _subscription = _repository.getAnnouncements(tenantId).listen((list) {
        _announcements = list;
        checkUnread(list);
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = "Erro ao carregar avisos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void clear() {
    _subscription?.cancel();
    _announcements = [];
    notifyListeners();
  }

  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.createAnnouncement(announcement);
    } catch (e) {
      _errorMessage = "Erro ao criar aviso: $e";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteAnnouncement(id);
    } catch (e) {
      _errorMessage = "Erro ao excluir aviso: $e";
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper para filtrar avisos importantes na UI se necessario
  List<AnnouncementModel> getImportantAnnouncements(
    List<AnnouncementModel> all,
  ) {
    return all.where((a) => a.isImportant).toList();
  }
}
