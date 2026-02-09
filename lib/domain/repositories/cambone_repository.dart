import '../../data/datasources/base_firestore_datasource.dart';
import '../models/cambone_model.dart';

class CamboneRepository extends BaseFirestoreDataSource {
  Future<List<CamboneSchedule>> getSchedules(String tenantId) async {
    try {
      final snapshot = await tenantCollection(
        'cambone_schedules',
      ).orderBy('date', descending: true).limit(20).get();

      return snapshot.docs
          .map(
            (doc) => CamboneSchedule.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar escalas de cambones: $e");
    }
  }

  Future<CamboneSchedule?> getScheduleByDate(
    DateTime date,
    String tenantId,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await tenantCollection('cambone_schedules')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return CamboneSchedule.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception("Erro ao buscar escala por data: $e");
    }
  }

  Future<void> saveSchedule(CamboneSchedule schedule, String tenantId) async {
    try {
      final data = schedule.toMap();
      // Remove o ID do map se for nulo ou vazio, ou se vamos gerar um novo
      // Mas aqui vamos usar add() se for novo, ou set() se já tiver ID.
      // Como o schedule pode vir sem ID (novo), vamos verificar.

      if (schedule.id.isEmpty) {
        await tenantCollection('cambone_schedules').add(data);
      } else {
        await tenantCollection('cambone_schedules').doc(schedule.id).set(data);
      }
    } catch (e) {
      throw Exception("Erro ao salvar escala de cambones: $e");
    }
  }

  Future<void> deleteSchedule(String id, String tenantId) async {
    try {
      await tenantCollection('cambone_schedules').doc(id).delete();
    } catch (e) {
      throw Exception("Erro ao deletar escala de cambones: $e");
    }
  }
}
