import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../colors.dart';
import '../../entrar.dart';
import '../../widgets/custom_text_field.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  String? nomeUsuarioLogado;

  final _dataEventoFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    nomeUsuarioLogado = ModalRoute.of(context)!.settings.arguments as String?;
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Limpeza':
        return Colors.blue;
      case 'Rito Aberto':
        return Colors.green;
      case 'Rito Fechado':
        return Colors.red;
      case 'Festa':
        return Colors.orange;
      case 'Kujiba':
        return Colors.purple;
      case 'Atendimento Tata':
        return const Color.fromARGB(255, 255, 166, 195);
      case 'Encruza':
        return Colors.yellow;
      case 'Curso':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Calendário'),
      ),
      body: Stack(children: [
        _buildListaEventos(),
        if (isAdmin) _buildBotaoAdicionarEvento()
      ]),
    );
  }

  Widget _buildListaEventos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('GiraMes')
          .orderBy('data')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar eventos.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum evento encontrado.'));
        }

        Map<String, List<QueryDocumentSnapshot>> eventosPorMes = {};
        for (var doc in snapshot.data!.docs) {
          final data =
              (doc.data() as Map<String, dynamic>)['data'] as Timestamp;
          final mes = DateFormat('MM').format(data.toDate());

          if (!eventosPorMes.containsKey(mes)) {
            eventosPorMes[mes] = [];
          }
          eventosPorMes[mes]!.add(doc);
        }

        return ListView.builder(
          itemCount: eventosPorMes.length,
          itemBuilder: (context, index) {
            String mes = eventosPorMes.keys.elementAt(index);
            List<QueryDocumentSnapshot> eventosDoMes = eventosPorMes[mes]!;

            return _buildEventosDoMes(mes, eventosDoMes);
          },
        );
      },
    );
  }

  Widget _buildEventosDoMes(
      String mes, List<QueryDocumentSnapshot> eventosDoMes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _nomeDoMes(mes),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        ...eventosDoMes.map((doc) {
          final evento = doc.data() as Map<String, dynamic>;
          final documentId = doc.id;
          return _buildItemEvento(evento, documentId);
        }).toList(),
      ],
    );
  }

  Widget _buildItemEvento(Map<String, dynamic> evento, String documentId) {
    final data = evento['data'];
    final titulo = evento['titulo'] ?? '';
    final descricao = evento['descricao'] ?? '';
    final tag = evento['tag'] ?? '';
    final tagColor = _getTagColor(tag);

    return Column(
      children: [
        isAdmin
            ? Dismissible(
                key: Key(documentId),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _excluirEvento(documentId),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: _buildListTileEvento(
                    data, titulo, descricao, documentId, evento, tagColor),
              )
            : _buildListTileEvento(
                data, titulo, descricao, documentId, evento, tagColor),
        const Divider(),
      ],
    );
  }

  ListTile _buildListTileEvento(Timestamp data, String titulo, String descricao,
      String documentId, Map<String, dynamic> evento, Color tagColor) {
    DateTime dataAsDateTime = data.toDate();
    String dataFormatada = DateFormat('dd/MM').format(dataAsDateTime);

    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
            color: tagColor, borderRadius: BorderRadius.circular(5.0)),
        width: 5,
        height: 200,
      ),
      title: Text('$dataFormatada - $titulo',
          style: GoogleFonts.lato(fontSize: 13)),
      onTap: () {
        if (isAdmin) {
          _mostrarDialogoEdicao(context, documentId, evento);
        } else {
          _mostrarDetalhes(context, documentId);
        }
      },
      trailing: isAdmin
          ? ElevatedButton(
              style: _buttonStyle(),
              onPressed: () => _mostrarPresencas(context, documentId),
              child: Text("Mostrar Lista de\nPresenças",
                  style: GoogleFonts.lato(color: kPrimaryColor, fontSize: 12)),
            )
          : ElevatedButton.icon(
              style: _buttonStyle(),
              onPressed: () => _marcarPresenca(documentId, nomeUsuarioLogado!),
              icon: const Icon(Icons.add, color: kPrimaryColor),
              label: Text("Confirmar\nPresença",
                  style: GoogleFonts.lato(color: kPrimaryColor, fontSize: 12)),
            ),
    );
  }

  String _nomeDoMes(String numeroMes) {
    switch (numeroMes) {
      case '01':
        return 'Janeiro';
      case '02':
        return 'Fevereiro';
      case '03':
        return 'Março';
      case '04':
        return 'Abril';
      case '05':
        return 'Maio';
      case '06':
        return 'Junho';
      case '07':
        return 'Julho';
      case '08':
        return 'Agosto';
      case '09':
        return 'Setembro';
      case '10':
        return 'Outubro';
      case '11':
        return 'Novembro';
      case '12':
        return 'Dezembro';
      default:
        return 'Mês inválido';
    }
  }

  ButtonStyle _buttonStyle() {
    return const ButtonStyle(
      elevation: MaterialStatePropertyAll(0),
      backgroundColor: MaterialStatePropertyAll(Colors.white),
    );
  }

  Widget _buildBotaoAdicionarEvento() {
    return Positioned(
      bottom: 70.0,
      right: 16.0,
      child: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAdicao(context),
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: kPrimaryColor),
        label: Text("Adicionar Evento",
            style: GoogleFonts.lato(fontSize: 13, color: kPrimaryColor)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
          side: const BorderSide(color: kPrimaryColor),
        ),
      ),
    );
  }

  Future<void> _excluirEvento(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('GiraMes')
          .doc(documentId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Evento excluído.')));
    } catch (e) {
      print("Erro ao excluir evento: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir evento.')));
    }
  }

  void _mostrarDialogoAdicao(BuildContext context) {
    final TextEditingController _dataController = TextEditingController();
    final TextEditingController _descricaoController = TextEditingController();
    final TextEditingController _tagController = TextEditingController();
    List<String> tiposDeEventos = [
      'Limpeza',
      'Rito Aberto',
      'Rito Fechado',
      'Festa',
      'Kujiba',
      'Atendimento Tata',
      'Encruza',
      'Curso',
    ];
    String? _selectedTipoEvento;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                icon: Icons.calendar_month,
                label: "Data Evento",
                controller: _dataController,
                inputFormatters: [_dataEventoFormatter],
              ),
              CustomTextField(
                icon: Icons.event,
                label: "Titulo Evento",
                controller: _descricaoController,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Evento',
                  icon: Icon(Icons.tips_and_updates),
                ),
                value: _selectedTipoEvento,
                items: tiposDeEventos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipoEvento = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Adicionar'),
              onPressed: () {
                String dataString = _dataController.text;
                try {
                  DateFormat format = DateFormat('dd/MM/yyyy');
                  DateTime dateTime =
                      format.parse('$dataString/${DateTime.now().year}');
                  Timestamp timestamp = Timestamp.fromDate(dateTime);

                  FirebaseFirestore.instance.collection('GiraMes').add({
                    'data': timestamp,
                    'titulo': _descricaoController.text,
                    'presencas': [],
                    'tag': _selectedTipoEvento,
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Formato de data inválido. Use dd/MM')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoEdicao(
      BuildContext context, String documentId, Map<String, dynamic> evento) {
    Timestamp timestampData = evento['data'];
    DateTime dateTimeData = timestampData.toDate();
    String initialDateString = DateFormat('dd/MM').format(dateTimeData);

    final TextEditingController _dataController =
        TextEditingController(text: initialDateString);
    final TextEditingController _tituloController =
        TextEditingController(text: evento['titulo'] ?? '');
    final TextEditingController _descricaoController =
        TextEditingController(text: evento['descricao'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                  icon: Icons.calendar_month,
                  label: "Data",
                  controller: _dataController,
                  inputFormatters: [_dataEventoFormatter]),
              CustomTextField(
                icon: Icons.title,
                label: "Titulo",
                controller: _tituloController,
              ),
              CustomTextField(
                icon: Icons.description,
                label: "Descrição",
                controller: _descricaoController,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () {
                String dataString = _dataController.text;
                try {
                  DateFormat format = DateFormat('dd/MM/yyyy');
                  DateTime dateTime =
                      format.parse('$dataString/${DateTime.now().year}');
                  Timestamp timestamp = Timestamp.fromDate(dateTime);

                  FirebaseFirestore.instance
                      .collection('GiraMes')
                      .doc(documentId)
                      .update({
                    'data': timestamp,
                    'titulo': _tituloController.text,
                    'descricao': _descricaoController.text,
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Formato de data inválido. Use dd/MM')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarPresencas(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lista de Presenças'),
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('GiraMes')
                .doc(documentId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return const Text('Erro ao carregar presenças.');
              }

              List<dynamic> presencas = snapshot.data!.get('presencas') ?? [];

              if (presencas.isEmpty) {
                return const Text('Ninguém confirmou presença ainda.');
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.7,
                child: ListView.builder(
                  itemCount: presencas.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(presencas[index]),
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _marcarPresenca(String documentId, String nomeUsuario) async {
    try {
      final documentReference =
          FirebaseFirestore.instance.collection('GiraMes').doc(documentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(documentReference);

        if (!snapshot.exists) {
          throw Exception('Document does not exist!');
        }

        List<dynamic> presencas = [];

        if (snapshot.data() != null &&
            (snapshot.data() as Map<String, dynamic>)
                .containsKey('presencas')) {
          presencas = List.from(snapshot.get('presencas'));
        }

        if (presencas.contains(nomeUsuario)) {
          presencas.remove(nomeUsuario);
        } else {
          presencas.add(nomeUsuario);
        }
        transaction.update(documentReference, {'presencas': presencas});
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presença marcada com sucesso!')));
    } catch (e) {
      print('Error marking attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao marcar presença.')));
    }
  }

  void _mostrarDetalhes(BuildContext context, String documentId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('GiraMes')
              .doc(documentId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Erro ao carregar detalhes.'));
            }

            final evento = snapshot.data!.data() as Map<String, dynamic>;
            final titulo = evento['titulo'] ?? '';
            final descricao = evento['descricao'] ?? '';
            final data = evento['data'] as Timestamp;
            final dataFormatada = DateFormat('dd/MM').format(data.toDate());

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$dataFormatada - $titulo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(descricao ?? "Não há detalhes para esse evento"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
