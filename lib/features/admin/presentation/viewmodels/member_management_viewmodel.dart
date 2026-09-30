import 'package:flutter/material.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';

import 'package:app_tenda/features/calendar/domain/repositories/event_repository.dart';
import 'package:app_tenda/features/finance/domain/repositories/payment_request_repository.dart';
import 'package:app_tenda/features/finance/presentation/viewmodels/receipt_approval_viewmodel.dart';
import 'package:app_tenda/features/home/presentation/viewmodels/home_viewmodel.dart';

class MemberManagementViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final EventRepository _eventRepository = getIt<EventRepository>();
  final PushTriggerService _pushService = getIt<PushTriggerService>();
  final PaymentRequestRepository _paymentRepository =
      getIt<PaymentRequestRepository>();

  MemberManagementViewModel(this._userRepository);

  Set<String> _approverIds = {};

  /// Se [userId] está na lista de aprovadores do financeiro.
  bool isFinanceApprover(String userId) => _approverIds.contains(userId);

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
      _approverIds = (await _loadApproverIds()).toSet();
      _applyFilter();
    } catch (e) {
      debugPrint("Erro ao carregar membros: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> _loadApproverIds() async {
    try {
      return await _paymentRepository.getApproverIds();
    } catch (e) {
      debugPrint("Erro ao carregar aprovadores do financeiro: $e");
      return [];
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

  Future<void> saveAmaciDates(
    UserModel user,
    DateTime? lastAmaci,
    DateTime? nextAmaci,
  ) async {
    try {
      await _userRepository.updateAmaciDates(user.id, lastAmaci, nextAmaci);

      // Se definiu um próximo Amaci, dispara notificação e sincroniza calendário
      if (nextAmaci != null) {
        // Sincroniza com calendário
        await _syncAmaciWithCalendar(nextAmaci, user.name);

        if (user.fcmTokens != null && user.fcmTokens!.isNotEmpty) {
          // Verifica se a data mudou ou é nova para não disparar à toa (opcional, mas bom ter)
          if (user.nextAmaciDate != nextAmaci) {
            final formattedDate = DateFormat('dd/MM/yyyy').format(nextAmaci);
            await _pushService.notifyAmaciSchedule(
              userName: user.name.split(' ')[0],
              userTokens: user.fcmTokens!,
              date: formattedDate,
            );
          }
        }
      }

      await loadMembers(); // Recarrega a lista
    } catch (e) {
      debugPrint("Erro ao salvar datas de Amaci: $e");
      rethrow;
    }
  }

  Future<void> _syncAmaciWithCalendar(DateTime date, String userName) async {
    try {
      // 1. Busca eventos de Amaci na data
      final events = await _eventRepository.getEventsByDateAndType(
        date,
        'Amaci',
      );

      if (events.isEmpty) {
        // 2. Se não existir, cria um novo evento
        await _eventRepository.addEvent(
          {
            'title': 'Amaci',
            'date': date.toIso8601String(),
            'type': 'Amaci',
            'description': 'Obrigação litúrgica de Amaci.',
            'cleaningCrew': [],
            'confirmedAttendance': [],
            'participants': [userName], // Já adiciona o primeiro participante
          },
          _pushService.runtimeType.toString(),
        ); // TenantID é pego no repository
      } else {
        // 3. Se existir, adiciona o participante ao primeiro evento encontrado
        final event = events.first;

        // Verifica se já não está na lista para não duplicar
        if (event.participants == null ||
            !event.participants!.contains(userName)) {
          await _eventRepository.addParticipantToEvent(event.id, userName);
        }
      }
    } catch (e) {
      debugPrint("Erro ao sincronizar com calendário: $e");
      // Não damos rethrow aqui para não travar o fluxo principal se o calendário falhar
    }
  }

  /// Marca ou desmarca um admin como aprovador de comprovantes. Só admins
  /// entram na lista: as regras exigem ser admin E constar nela.
  Future<void> toggleFinanceApprover(UserModel user) async {
    if (!user.isAdmin) {
      throw StateError('Só administradores podem ser aprovadores do financeiro.');
    }
    final enable = !isFinanceApprover(user.id);

    try {
      await _paymentRepository.setApprover(user.id, enabled: enable);
      if (enable) {
        _approverIds.add(user.id);
      } else {
        _approverIds.remove(user.id);
      }
      notifyListeners();
      await _refreshOwnApproverState();
    } catch (e) {
      debugPrint("Erro ao alterar aprovador do financeiro: $e");
      rethrow;
    }
  }

  /// Atualiza o card "Comprovantes" do hub caso quem mexeu na lista seja o
  /// próprio aprovador logado.
  Future<void> _refreshOwnApproverState() async {
    await getIt<ReceiptApprovalViewModel>().init(
      getIt<HomeViewModel>().currentUser,
    );
  }

  Future<void> toggleAdminRole(UserModel user) async {
    final newRole = user.isAdmin ? 'user' : 'admin';
    final updatedUser = user.copyWith(role: newRole);

    try {
      await _userRepository.saveUserProfile(updatedUser);

      // Quem deixa de ser admin sai da lista de aprovadores. As regras já o
      // barrariam, mas assim a lista não guarda ids sem efeito.
      if (user.isAdmin && isFinanceApprover(user.id)) {
        try {
          await _paymentRepository.setApprover(user.id, enabled: false);
          _approverIds.remove(user.id);
        } catch (e) {
          debugPrint("Erro ao remover aprovador rebaixado: $e");
        }
      }

      // Atualiza a lista localmente para refletir a mudança imediatamente
      final index = _allMembers.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _allMembers[index] = updatedUser;
        _applyFilter(); // Re-aplica filtros se houver
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao alterar permissão de admin: $e");
      rethrow;
    }
  }
}
