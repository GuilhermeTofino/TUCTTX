import '../data/calendario_data.dart';
import '../models/calendario_model.dart';

class CalendarioBloc {
  final CalendarioData _calendarioData = CalendarioData();
  List<CalendarioModel> _eventos = [];
  Function(List<CalendarioModel>)? onUpdate;

  void carregarEventos() {
    _calendarioData.getEventosStream().listen((eventos) {
      _eventos = eventos;
      onUpdate?.call(_eventos);
    });
  }

  void adicionarEvento(CalendarioModel evento) async {
    await _calendarioData.adicionarEvento(evento);
  }

  void editarEvento(CalendarioModel evento) async {
    await _calendarioData.editarEvento(evento);
  }

  void excluirEvento(String id) async {
    await _calendarioData.excluirEvento(id);
  }

  void marcarPresenca(String id, String usuario) async {
    await _calendarioData.marcarPresenca(id, usuario);
  }
}