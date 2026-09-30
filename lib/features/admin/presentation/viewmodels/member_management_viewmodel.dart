import 'package:flutter/material.dart';
import 'package:app_tenda/features/auth/domain/models/user_model.dart';
import 'package:app_tenda/features/auth/domain/repositories/user_repository.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/services/push_trigger_service.dart';

import 'package:app_tenda/features/admin/domain/member_tabs.dart';
import 'package:app_tenda/features/admin/domain/models/audit_log_entry.dart';
import 'package:app_tenda/features/admin/domain/repositories/access_control_repository.dart';
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
  final AccessControlRepository _accessRepository =
      getIt<AccessControlRepository>();

  MemberManagementViewModel(this._userRepository);

  Set<String> _approverIds = {};

  /// Se [userId] está na lista de aprovadores do financeiro.
  bool isFinanceApprover(String userId) => _approverIds.contains(userId);

  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<UserModel> get members => _filteredMembers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  /// Usuários de uma aba (consulentes, membros ou admins), com a busca aplicada.
  List<UserModel> membersFor(MemberTab tab) =>
      usersForTab(_allMembers, tab, query: _searchQuery);

  /// Quantos usuários a aba mostra agora (respeita a busca).
  int countFor(MemberTab tab) => membersFor(tab).length;

  /// Consulentes que pediram para virar membro (status pending_approval).
  List<UserModel> get pendingApprovalMembers => _allMembers
      .where((u) => u.isVisitor && u.isPendingApproval)
      .toList();

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
    Iterable<UserModel> list = _allMembers;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where(
        (u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q),
      );
    }
    _filteredMembers = list.toList()..sort((a, b) => a.name.compareTo(b.name));
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

  // ---------------------------------------------------------------------------
  // ACESSO (papel, status, skills): sempre pelo AccessControlRepository, que grava
  // a mudança e o audit_log na mesma transação, com o admin logado como ator.
  // ---------------------------------------------------------------------------

  String get _actorId {
    final id = getIt<HomeViewModel>().currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Sessão expirada. Entre novamente.');
    }
    return id;
  }

  int get _adminCount => _allMembers.where((u) => u.isAdmin).length;

  /// Trava de segurança: ninguém altera o próprio acesso, e o último admin não
  /// pode ser rebaixado (o app ficaria sem quem administre).
  void _guardAccessChange(UserModel target, {required bool losesAdmin}) {
    if (target.id == _actorId) {
      throw StateError('Você não pode alterar o seu próprio acesso.');
    }
    if (losesAdmin && target.isAdmin && _adminCount <= 1) {
      throw StateError('Este é o último administrador e não pode ser rebaixado.');
    }
  }

  Future<void> _changeAccess(
    UserModel user,
    Map<String, dynamic> changes,
  ) async {
    try {
      await _accessRepository.applyAccessChange(
        targetUserId: user.id,
        actorId: _actorId,
        changes: changes,
      );
      _patchLocal(
        user.id,
        role: changes['role'] as String?,
        status: changes['status'] as String?,
        skills: changes['skills'] == null
            ? null
            : List<String>.from(changes['skills'] as List),
      );
    } catch (e) {
      debugPrint("Erro ao alterar acesso: $e");
      rethrow;
    }
  }

  /// Atualiza a cópia local do membro, sem reler a lista inteira.
  void _patchLocal(String id, {String? role, String? status, List<String>? skills}) {
    final index = _allMembers.indexWhere((u) => u.id == id);
    if (index == -1) return;
    _allMembers[index] = _allMembers[index].copyWith(
      role: role,
      status: status,
      skills: skills,
    );
    _applyFilter();
    notifyListeners();
  }

  /// Tira o admin da lista de aprovadores do financeiro (as regras já o barrariam
  /// sem o papel de admin, mas assim a lista não guarda ids sem efeito).
  Future<void> _dropFromApproversIfListed(String userId) async {
    if (!isFinanceApprover(userId)) return;
    try {
      await _paymentRepository.setApprover(userId, enabled: false);
      _approverIds.remove(userId);
    } catch (e) {
      debugPrint("Erro ao remover aprovador rebaixado: $e");
    }
  }

  /// Promove a admin ou remove o papel de admin (volta a 'user').
  Future<void> toggleAdminRole(UserModel user) async {
    _guardAccessChange(user, losesAdmin: user.isAdmin);
    await _changeAccess(user, {'role': user.isAdmin ? 'user' : 'admin'});
    if (user.isAdmin) await _dropFromApproversIfListed(user.id);
  }

  /// Aprova um consulente como membro ("filho de santo"): role 'user', status 'active'.
  Future<void> approveVisitor(UserModel user) async {
    if (!user.isVisitor) {
      throw StateError('Só consulentes são aprovados.');
    }
    _guardAccessChange(user, losesAdmin: false);
    await _changeAccess(user, {'role': 'user', 'status': 'active'});
  }

  /// Define as skills de um membro (role 'user'). Admin já tem todas.
  Future<void> setSkills(UserModel user, List<String> skills) async {
    if (user.role != 'user') {
      throw StateError('Skills só se aplicam a membros (filhos de santo).');
    }
    _guardAccessChange(user, losesAdmin: false);
    await _changeAccess(user, {'skills': skills});
  }

  /// Rebaixa um membro para consulente: perde skills e volta a status 'active'.
  Future<void> demoteToVisitor(UserModel user) async {
    _guardAccessChange(user, losesAdmin: true);
    await _changeAccess(user, {
      'role': 'visitor',
      'status': 'active',
      'skills': <String>[],
    });
    await _dropFromApproversIfListed(user.id);
  }

  // ---------------------------------------------------------------------------
  // HISTÓRICO E DESFAZER
  // ---------------------------------------------------------------------------

  Future<List<SkillDefinition>> loadSkillsCatalog() =>
      _accessRepository.getSkillsCatalog();

  Future<List<AuditLogEntry>> loadHistory(String userId) =>
      _accessRepository.getHistory(userId);

  /// Desfaz uma entrada do histórico. Lança [StateError] com o motivo se o
  /// acesso do membro mudou depois dela.
  Future<void> undo(AuditLogEntry entry) async {
    await _accessRepository.undo(logId: entry.id, actorId: _actorId);
    // O desfazer pode ter mudado papel/status/skills: relê o membro.
    await loadMembers();
  }
}
