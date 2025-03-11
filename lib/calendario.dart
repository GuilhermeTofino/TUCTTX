import 'package:app_tenda/widgets/fcm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'widgets/colors.dart';
import '../entrar.dart';
import '../widgets/custom_text_field.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  String? nomeUsuarioLogado;
  late String _mesAtual;
  Map<String, bool> _expandedMonths =
      {}; // Controla quais meses estão expandidos

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

  @override
  void initState() {
    super.initState();
    _mesAtual = DateFormat('MM').format(DateTime.now()); // Obtém o mês atual
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

        // Agrupar eventos por mês
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

        // Define os meses expandidos
        for (String mes in eventosPorMes.keys) {
          _expandedMonths.putIfAbsent(mes, () => mes == _mesAtual);
        }

        return ListView.builder(
          itemCount: eventosPorMes.length,
          itemBuilder: (context, index) {
            String mes = eventosPorMes.keys.elementAt(index);
            List<QueryDocumentSnapshot> eventos = eventosPorMes[mes]!;
            return _buildEventosDoMes(mes, eventos);
          },
        );
      },
    );
  }

  Widget _buildEventosDoMes(
      String mes, List<QueryDocumentSnapshot> eventosDoMes) {
    return ExpansionTile(
      dense: true,
      shape: Border.all(color: Colors.white),
      title: Text(
        _nomeDoMes(mes),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded:
          _expandedMonths[mes] ?? false, // Define se o mês está expandido
      onExpansionChanged: (expanded) {
        setState(() {
          _expandedMonths[mes] = expanded;
        });
      },
      children: eventosDoMes.map((doc) {
        final evento = doc.data() as Map<String, dynamic>;
        final documentId = doc.id;
        return _buildItemEvento(evento, documentId);
      }).toList(),
    );
  }

  Widget _buildItemEvento(Map<String, dynamic> evento, String documentId) {
    final data = evento['data'];
    final titulo = evento['titulo'] ?? '';
    final descricao = evento['descricao'] ?? '';
    final tag = evento['tag'] ?? '';
    final tagColor = _getTagColor(tag);

    bool usuarioConfirmado = evento['presencas'] != null &&
        (evento['presencas'] as List).contains(nomeUsuarioLogado);

    return Column(
      children: [
        ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: tagColor,
              borderRadius: BorderRadius.circular(0.0),
            ),
            width: 10,
            height: 60,
          ),
          dense: true,
          title: Text(
            '${DateFormat('dd/MM').format((data as Timestamp).toDate())} - $titulo',
            style: GoogleFonts.lato(fontSize: 13),
          ),
          onTap: () {
            if (isAdmin) {
              _mostrarDialogoEdicao(context, documentId, evento);
            } else {
              _mostrarDetalhes(context, documentId);
            }
          },
          trailing: Wrap(
            spacing: 3, // Espaço entre os ícones
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton(
                    text: "Vou",
                    isSelected: usuarioConfirmado,
                    color: Colors.green,
                    onTap: () =>
                        _marcarPresenca(documentId, nomeUsuarioLogado!, true),
                  ),
                  const SizedBox(height: 3), // Espaço entre os botões
                  _buildToggleButton(
                    text: "Não Vou",
                    isSelected: !usuarioConfirmado,
                    color: Colors.red,
                    onTap: () =>
                        _marcarPresenca(documentId, nomeUsuarioLogado!, false),
                  ),
                ],
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.list, color: kPrimaryColor),
                  onPressed: () => _mostrarPresencas(context, documentId),
                  tooltip: "Exibir Lista de Presenças",
                ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[350],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildBotaoAdicionarEvento() {
    return Positioned(
      bottom: 70.0,
      right: 16.0,
      child: FloatingActionButton.extended(
        heroTag: "botaoAdicionarEvento",
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
      case 'Amaci':
        return Colors.white;
      default:
        return Colors.grey;
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
      'Amaci',
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

  Future<void> _marcarPresenca(
      String documentId, String nomeUsuario, bool vou) async {
    try {
      final documentReference =
          FirebaseFirestore.instance.collection('GiraMes').doc(documentId);

      String tituloEvento = "Evento sem nome"; // Definição inicial

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(documentReference);

        if (!snapshot.exists) throw Exception('Documento não existe!');

        Map<String, dynamic> evento = snapshot.data() as Map<String, dynamic>;
        List<dynamic> presencas = evento['presencas'] ?? [];
        tituloEvento = evento['titulo'] ??
            'Evento sem nome'; // Atribuindo o título corretamente

        vou ? presencas.add(nomeUsuario) : presencas.remove(nomeUsuario);

        transaction.update(documentReference, {'presencas': presencas});

        // 🔥 Enviar FCM após confirmar presença com título do evento
        if (vou) {
          await sendFCMMessage(
            "O Filho $nomeUsuario confirmou presença no evento: $tituloEvento",
            "Presença Confirmada!",
            nomeUsuario,
          );
        }
      });

      // ✅ Agora `tituloEvento` está acessível aqui
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vou
              ? 'Presença confirmada no evento: $tituloEvento!'
              : 'Presença removida!'),
        ),
      );

      setState(() {});
    } catch (e) {
      print('Erro ao marcar presença: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao marcar presença.')),
      );
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
