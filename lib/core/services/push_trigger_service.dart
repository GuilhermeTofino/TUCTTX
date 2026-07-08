import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';

class PushTriggerService extends BaseFirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adiciona uma solicitação de notificação na fila para ser processada pela Cloud Function.
  Future<void> _enqueueNotification({
    String? topic,
    List<String>? tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _firestore.collection('notifications_queue').add({
      'topic': topic,
      'tokens': tokens,
      'title': title,
      'body': body,
      'data': data,
      'tenantId': tenantId,
      'env': env,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Notifica todos os usuários do tenant sobre um novo evento.
  Future<void> notifyNewEvent(String eventTitle) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '📅 Nova Gira Agendada!',
      body:
          'Uma nova gira foi adicionada ao calendário: $eventTitle. Confira os detalhes!',
      data: {'type': 'event_created'},
    );
  }

  /// Notifica todos os usuários sobre o cancelamento de uma gira.
  Future<void> notifyEventCancelled(String eventTitle) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '🚫 Gira Cancelada',
      body: 'A gira "$eventTitle" foi removida do calendário ou cancelada.',
      data: {'type': 'event_cancelled'},
    );
  }

  /// Notifica um usuário específico sobre sua escala de faxina.
  Future<void> notifyCleaningDuty({
    required String userId,
    required List<String> userTokens,
    required String date,
  }) async {
    if (userTokens.isEmpty) return;

    await _enqueueNotification(
      tokens: userTokens,
      title: '🧼 Escala de Faxina',
      body:
          'Olá! Você foi escalado para a faxina no dia $date. Contamos com você!',
      data: {'type': 'cleaning_duty', 'date': date},
    );
  }

  /// Notifica sobre mensalidade em atraso.
  Future<void> notifyLateFee({
    required String userName,
    required List<String> userTokens,
    required String month,
  }) async {
    if (userTokens.isEmpty) return;

    await _enqueueNotification(
      tokens: userTokens,
      title: '💰 Lembrete de Mensalidade',
      body:
          'Olá $userName! Consta em nosso sistema a mensalidade de $month em aberto. Poderia verificar, por favor?',
      data: {'type': 'finance_reminder', 'category': 'fee'},
    );
  }

  /// Notifica sobre dívida de bazar em aberto.
  Future<void> notifyBazaarDebt({
    required String userName,
    required List<String> userTokens,
    required String itemName,
  }) async {
    if (userTokens.isEmpty) return;

    await _enqueueNotification(
      tokens: userTokens,
      title: '🛍️ Lembrete do Bazar',
      body:
          'Olá $userName! Passando para lembrar da sua compra ($itemName) no bazar. Contamos com sua colaboração!',
      data: {'type': 'finance_reminder', 'category': 'bazaar'},
    );
  }

  /// Notifica sobre agendamento de Amaci.
  Future<void> notifyAmaciSchedule({
    required String userName,
    required List<String> userTokens,
    required String date,
  }) async {
    if (userTokens.isEmpty) return;

    await _enqueueNotification(
      tokens: userTokens,
      title: '🌿 Próximo Amaci Agendado',
      body:
          'Olá $userName! Seu próximo Amaci foi agendado para o dia $date. Prepare-se! 🙏',
      data: {'type': 'amaci_scheduled', 'date': date},
    );
  }

  /// Notifica todos os usuários sobre um aviso urgente no mural.
  Future<void> notifyUrgentAnnouncement({
    required String title,
    required String content,
  }) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '🚨 Aviso Urgente: $title',
      body: content.length > 100 ? '${content.substring(0, 97)}...' : content,
      data: {'type': 'announcement_urgent'},
    );
  }

  /// Notifica sobre novo material de estudo.
  Future<void> notifyNewStudyMaterial({
    required String topicName,
    required String title,
    required String folder,
  }) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '📚 Novo Estudo: $topicName',
      body: folder.isNotEmpty
          ? 'Novo arquivo em "$folder": $title'
          : 'Novo arquivo adicionado: $title',
      data: {'type': 'study_material'},
    );
  }

  /// Notifica sobre nova escala de cambones.
  Future<void> notifyNewCamboneSchedule(String eventTitle) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '📋 Nova Escala de Cambones',
      body: 'A escala para "$eventTitle" já está disponível. Confira!',
      data: {'type': 'cambone_schedule_new', 'route': '/cambone-list'},
    );
  }

  /// Notifica sobre atualização em escala de cambones.
  Future<void> notifyUpdatedCamboneSchedule(String eventTitle) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '🔄 Escala Atualizada',
      body:
          'A escala para "$eventTitle" sofreu alterações. Verifique se seu nome mudou!',
      data: {'type': 'cambone_schedule_update', 'route': '/cambone-list'},
    );
  }

  /// Notifica sobre exclusão de escala de cambones.
  Future<void> notifyDeletedCamboneSchedule(String eventTitle) async {
    final tenantId = AppConfig.instance.tenant.tenantSlug;
    final env = AppConfig.instance.environment.name;

    await _enqueueNotification(
      topic: '${tenantId}_${env}_all',
      title: '❌ Escala Cancelada',
      body:
          'Atenção: A escala de cambones para "$eventTitle" foi cancelada/removida.',
      data: {'type': 'cambone_schedule_delete'},
    );
  }
}
