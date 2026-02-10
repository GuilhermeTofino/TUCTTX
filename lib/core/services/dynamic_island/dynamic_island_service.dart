import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DynamicIslandService {
  final _liveActivitiesPlugin = LiveActivities();
  String? _latestActivityId;
  bool _isInitialized = false;

  // Priority system
  int _currentPriority =
      0; // 0 = none, 1 = event, 2 = announcement, 3 = important
  String _currentContentType = ''; // 'event', 'announcement', 'important'
  Map<String, dynamic>?
  _savedEventData; // Backup do evento para restaurar depois

  /// Inicializa o plugin com o App Group correto baseado no flavor atual
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final bundleId = packageInfo.packageName;
      final appGroupId = 'group.$bundleId';

      await _liveActivitiesPlugin.init(appGroupId: appGroupId);
      _isInitialized = true;
      print("DynamicIslandService inicializado com App Group: $appGroupId");
    } catch (e) {
      print("Falha ao inicializar DynamicIslandService: $e");
    }
  }

  /// Inicia uma nova atividade na Dynamic Island
  /// [eventName] - Nome do evento (ex: Gira de Baianos)
  /// [eventType] - Tipo (ex: Pública, Festa)
  /// [eventDate] - Horário formatado (ex: 19:30)
  /// [status] - Status inicial (ex: Em breve)
  /// [eventDescription] - Descrição opcional
  Future<void> startActivity({
    required String eventName,
    required String eventType,
    required String eventDate,
    required String status,
    String? eventDescription,
    String? primaryColor,
  }) async {
    // Garantir que o serviço está inicializado
    await initialize();

    // Definimos os atributos iniciais que serão passados para o Swift
    final Map<String, dynamic> activityAttributes = {
      'eventName': eventName,
      'eventType': eventType,
      'eventDate': eventDate,
      'eventDescription': eventDescription,
      'status': status,
      'primaryColor': primaryColor ?? '#673AB7',
    };

    // Salvar dados do evento para restaurar depois (se um aviso sobrescrever)
    _savedEventData = Map.from(activityAttributes);

    // Verificar se há conteúdo de maior prioridade ativo
    if (_currentPriority >= 2) {
      print('⏸️ Evento salvo, mas não exibido (há aviso com prioridade maior)');
      return;
    }

    try {
      // O primeiro argumento 'activityId' deve coincidir com o nome do Struct no Swift
      // No nosso caso: AppLiveActivityAttributes
      _latestActivityId = await _liveActivitiesPlugin.createActivity(
        'AppLiveActivityAttributes',
        activityAttributes,
      );
      _currentPriority = 1;
      _currentContentType = 'event';
      print(
        "✅ Atividade de Evento iniciada: $_latestActivityId (Prioridade: 1)",
      );
    } catch (e) {
      print("❌ Erro ao iniciar Dynamic Island: $e");
    }
  }

  /// Atualiza a atividade atual com novos dados
  Future<void> updateActivity({
    required String status,
    String? eventName,
    String? eventType,
    String? eventDate,
    String? eventDescription,
    String? primaryColor,
  }) async {
    if (_latestActivityId == null) return;

    final Map<String, dynamic> updatedContent = {'status': status};
    if (primaryColor != null) updatedContent['primaryColor'] = primaryColor;

    try {
      await _liveActivitiesPlugin.updateActivity(
        _latestActivityId!,
        updatedContent,
      );
    } catch (e) {
      print("Erro ao atualizar Dynamic Island: $e");
    }
  }

  /// Encerra a atividade atual
  Future<void> stopActivity() async {
    if (_latestActivityId == null) return;

    try {
      await _liveActivitiesPlugin.endActivity(_latestActivityId!);
      _latestActivityId = null;
    } catch (e) {
      print("Erro ao encerrar Dynamic Island: $e");
    }
  }

  /// Atualiza a atividade existente para mostrar um Aviso
  /// (Evita criar múltiplas atividades - iOS limita a 2)
  /// Sistema de Prioridades: IMPORTANTE (3) > AVISO (2) > EVENTO (1)
  Future<void> startAnnouncement({
    required String title,
    required String content,
    bool isImportant = false,
    String? primaryColor,
  }) async {
    // Garantir que o serviço está inicializado
    await initialize();

    final status = isImportant ? "URGENTE" : "Novo Aviso";
    final type = isImportant ? "IMPORTANTE" : "AVISO";
    final newPriority = isImportant ? 3 : 2;

    // Formata hora atual HH:mm
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeString = "$hour:$minute";

    final Map<String, dynamic> activityData = {
      'eventName': title,
      'eventType': type,
      'eventDate': timeString,
      'eventDescription': content,
      'status': status,
      'primaryColor': primaryColor ?? '#673AB7',
    };

    try {
      // Se já existe uma atividade, atualiza ela
      if (_latestActivityId != null) {
        print(
          "📱 Atualizando atividade existente com aviso (Prioridade: $newPriority)",
        );
        await _liveActivitiesPlugin.updateActivity(
          _latestActivityId!,
          activityData,
        );
        _currentPriority = newPriority;
        _currentContentType = isImportant ? 'important' : 'announcement';
        print("✅ Atividade atualizada com aviso: $title");
      } else {
        // Se não existe, cria uma nova
        print(
          "📱 Criando nova atividade para aviso (Prioridade: $newPriority)",
        );
        _latestActivityId = await _liveActivitiesPlugin.createActivity(
          'AppLiveActivityAttributes',
          activityData,
        );
        _currentPriority = newPriority;
        _currentContentType = isImportant ? 'important' : 'announcement';
        print("✅ Atividade de Aviso criada: $_latestActivityId");
      }
    } catch (e) {
      print("❌ Erro ao mostrar Aviso na Dynamic Island: $e");
    }
  }

  /// Restaura o evento salvo (quando o aviso for descartado/lido)
  Future<void> restoreEvent() async {
    if (_savedEventData == null || _latestActivityId == null) {
      print('⚠️ Nenhum evento salvo para restaurar');
      return;
    }

    // Só restaura se não houver conteúdo de maior prioridade
    if (_currentPriority >= 2) {
      print('⏸️ Não restaurando evento (ainda há aviso ativo)');
      return;
    }

    try {
      print('🔄 Restaurando evento na Dynamic Island');
      await _liveActivitiesPlugin.updateActivity(
        _latestActivityId!,
        _savedEventData!,
      );
      _currentPriority = 1;
      _currentContentType = 'event';
      print('✅ Evento restaurado com sucesso');
    } catch (e) {
      print('❌ Erro ao restaurar evento: $e');
    }
  }

  // MARK: - Getters públicos

  /// Retorna a prioridade do conteúdo atual (0-3)
  int get currentPriority => _currentPriority;

  /// Retorna o tipo de conteúdo atual ('event', 'announcement', 'important')
  String get currentContentType => _currentContentType;

  /// Verifica se há um evento salvo que pode ser restaurado
  bool get hasEventBackup => _savedEventData != null;

  /// Monitora o estado de todas as atividades
  Stream<ActivityUpdate> get activityUpdateStream =>
      _liveActivitiesPlugin.activityUpdateStream;
}
