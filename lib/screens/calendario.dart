import 'package:app_tenda/widgets/fcm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../widgets/colors.dart';
import '../../entrar.dart';
import '../../widgets/custom_text_field.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  String? nomeUsuarioLogado;
  late String _mesAtual;
  Map<String, bool> _expandedMonths = {};
  Map<String, bool> _loadingStates = {};

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

  void _mostrarLegenda() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 100,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Calendário'),
        actions: [
          TextButton(
            onPressed: _mostrarLegenda,
            child: const Text(
              'Ver Legenda',
              style: TextStyle(color: kPrimaryColor),
            ),
          ),
        ],
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
        Dismissible(
          key: UniqueKey(),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 50.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (!isAdmin) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Você não tem permissão para excluir o evento.')));
              return false;
            }
            return true;
          },
          onDismissed: (direction) async {
            final formattedDate = DateFormat('dd/MM').format((data).toDate());
            await FirebaseFirestore.instance
                .collection('GiraMes')
                .doc(documentId)
                .delete();
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
                    token);
              }
            }
          },
          child: ListTile(
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
                _loadingStates[documentId] == true
                    ? const SizedBox(
                        width: 80,
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2.0, color: kPrimaryColor),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleButton(
                            text: "Vou",
                            isSelected: usuarioConfirmado,
                            color: Colors.green,
                            onTap: () => _marcarPresenca(
                                documentId, nomeUsuarioLogado!, true),
                          ),
                          const SizedBox(height: 3), // Espaço entre os botões
                          _buildToggleButton(
                            text: "Não Vou",
                            isSelected: !usuarioConfirmado,
                            color: Colors.red,
                            onTap: () => _marcarPresenca(
                                documentId, nomeUsuarioLogado!, false),
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
        elevation: 0,
        backgroundColor: Colors.transparent,
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

  Widget _buildLegend() {
    final legendItems = [
      {'tag': 'Rito Aberto', 'color': Colors.green},
      {'tag': 'Rito Fechado', 'color': Colors.red},
      {'tag': 'Festa', 'color': Colors.orange},
      {'tag': 'Curso', 'color': Colors.teal},
      {'tag': 'Limpeza', 'color': Colors.blue},
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 2.0,
        runSpacing: 2.0,
        children: legendItems.map((item) {
          return SizedBox(
            width: 100,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: item['color'] as Color,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item['tag'] as String,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
      case 'Curso':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _mostrarDialogoAdicao(BuildContext context) {
    final TextEditingController _dataController = TextEditingController();
    final TextEditingController _descricaoController = TextEditingController();
    final TextEditingController _tagController = TextEditingController();
    List<String> tiposDeEventos = [
      'Rito Aberto',
      'Rito Fechado',
      'Festa',
      'Curso',
      'Limpeza',
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
                  border: OutlineInputBorder(),
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
              onPressed: () async {
                String dataString = _dataController.text;
                try {
                  DateFormat format = DateFormat('dd/MM/yyyy');
                  DateTime dateTime =
                      format.parse('$dataString/${DateTime.now().year}');
                  Timestamp timestamp = Timestamp.fromDate(dateTime);

                  // Adiciona o evento na coleção 'GiraMes'
                  DocumentReference docRef = await FirebaseFirestore.instance
                      .collection('GiraMes')
                      .add({
                    'data': timestamp,
                    'titulo': _descricaoController.text,
                    'presencas': [],
                    'tag': _selectedTipoEvento,
                  });

                  // Prepara a mensagem vibrante para o FCM
                  String fcmTitle = "Fique de olho no calendário!";
                  String fcmBody =
                      "Dia ${DateFormat('dd/MM').format(dateTime)} terá ${_descricaoController.text} e será $_selectedTipoEvento, não esqueça de marcar a sua presença";

                  // Consulta todos os usuários com fcm_token salvo
                  QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
                      .collection("Usuarios")
                      .where("fcm_token", isNotEqualTo: "")
                      .get();
                  for (var doc in usersSnapshot.docs) {
                    String token = doc["fcm_token"];
                    if (token.isNotEmpty) {
                      await sendFCMMessage(fcmBody, fcmTitle, token);
                    }
                  }

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
              presencas.sort((a, b) => a
                  .toString()
                  .toLowerCase()
                  .compareTo(b.toString().toLowerCase()));

              if (presencas.isEmpty) {
                return const Text('Ninguém confirmou presença ainda.');
              }
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width * 0.7,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: presencas.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(presencas[index]),
                      );
                    },
                  ),
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
    setState(() {
      _loadingStates[documentId] = true;
    });
    try {
      final documentReference =
          FirebaseFirestore.instance.collection('GiraMes').doc(documentId);
      String tituloEvento = "Evento sem nome";

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(documentReference);
        if (!snapshot.exists) throw Exception('Documento não existe!');
        Map<String, dynamic> evento = snapshot.data() as Map<String, dynamic>;
        List<dynamic> presencas = evento['presencas'] ?? [];
        tituloEvento = evento['titulo'] ?? 'Evento sem nome';
        vou ? presencas.add(nomeUsuario) : presencas.remove(nomeUsuario);
        transaction.update(documentReference, {'presencas': presencas});
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vou
              ? 'Presença confirmada no evento: $tituloEvento!'
              : 'Presença removida!'),
        ),
      );
    } catch (e) {
      print('Erro ao marcar presença: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao marcar presença.')),
      );
    } finally {
      setState(() {
        _loadingStates[documentId] = false;
      });
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
