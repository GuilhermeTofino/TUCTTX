import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendario_model.dart';

class CalendarioData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = "GiraMes";

  Stream<List<CalendarioModel>> getEventosStream() {
    return _firestore.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CalendarioModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> adicionarEvento(CalendarioModel evento) async {
    await _firestore.collection(collectionPath).add(evento.toMap());
  }

  Future<void> editarEvento(CalendarioModel evento) async {
    await _firestore
        .collection(collectionPath)
        .doc(evento.id)
        .update(evento.toMap());
  }

  Future<void> excluirEvento(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  Future<void> marcarPresenca(String id, String usuario) async {
    DocumentReference docRef = _firestore.collection(collectionPath).doc(id);
    await docRef.update({
      'participantes': FieldValue.arrayUnion([usuario]),
    });
  }
}
