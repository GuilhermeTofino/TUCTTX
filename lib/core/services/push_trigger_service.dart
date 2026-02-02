import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../../data/datasources/base_firestore_datasource.dart';

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
}
