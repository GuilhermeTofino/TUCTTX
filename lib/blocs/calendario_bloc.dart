// lib/bloc/calendario_bloc.dart
import 'dart:async';
import 'package:app_tenda/models/evento_model.dart';
import 'package:app_tenda/widgets/fcm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../data/evento_repository.dart';

class CalendarioBloc {
  final EventoRepository _repository = EventoRepository();

  // Stream de eventos para a UI
  Stream<List<Evento>> get eventosStream => _repository.getEventos();

  // Marca a presença (adiciona ou remove o usuário na lista de presenças)
  Future<void> marcarPresenca(
      String documentId, String nomeUsuario, bool vou) async {
    final docRef =
        FirebaseFirestore.instance.collection('GiraMes').doc(documentId);
    String tituloEvento = "Evento sem nome";

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Documento não existe!');
      Map<String, dynamic> eventoData = snapshot.data() as Map<String, dynamic>;
      List<dynamic> presencas = eventoData['presencas'] ?? [];
      tituloEvento = eventoData['titulo'] ?? 'Evento sem nome';
      if (vou) {
        if (!presencas.contains(nomeUsuario)) presencas.add(nomeUsuario);
      } else {
        presencas.remove(nomeUsuario);
      }
      transaction.update(docRef, {'presencas': presencas});
    });

    // Se o usuário marcou presença, envia notificação para os administradores
    if (vou) {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection("Usuarios")
          .where("funcao", isEqualTo: "administrador")
          .where("fcm_token", isNotEqualTo: "")
          .get();
      for (var doc in adminSnapshot.docs) {
        String adminToken = doc["fcm_token"];
        if (adminToken.isNotEmpty) {
          await sendFCMMessage(
            "$nomeUsuario confirmou presença no rito $tituloEvento",
            "Presença Confirmada!",
            adminToken,
          );
        }
      }
    }
  }

  // Exclui um evento e envia notificação para os usuários
  Future<void> deleteEvento(String documentId, Timestamp data) async {
    final formattedDate = DateFormat('dd/MM').format(data.toDate());
    await _repository.deleteEvento(documentId);
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .where('fcm_token', isNotEqualTo: '')
        .get();
    for (var doc in usersSnapshot.docs) {
      String token = doc['fcm_token'];
      if (token.isNotEmpty) {
        await sendFCMMessage(
          'Evento do dia $formattedDate foi cancelado.',
          'Evento Cancelado',
          token,
        );
      }
    }
  }

  // Adiciona um novo evento
  Future<void> addEvento(Map<String, dynamic> eventData) async {
    await _repository.addEvento(eventData);
  }

  // Atualiza os dados de um evento
  Future<void> updateEvento(
      String documentId, Map<String, dynamic> updatedData) async {
    await _repository.updateEvento(documentId, updatedData);
  }
}
