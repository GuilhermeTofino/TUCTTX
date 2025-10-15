import 'package:app_tenda/entrar.dart';
import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/widgets/fcm.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String type;
  final String title;
  final DateTime date;
  final List<String> attendees;
  final List<String> scaleAttendees;
  Event(
      {required this.id,
      required this.type,
      required this.title,
      required this.date,
      required this.attendees,
      required this.scaleAttendees});
  factory Event.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawAttendees = data['attendees'];
    final attendeesList = <String>[];
    if (rawAttendees is List) {
      for (var item in rawAttendees) {
        if (item != null) {
          attendeesList.add(item.toString());
        }
      }
    }
    final rawScale = data['scaleAttendees'];
    final scaleList = <String>[];
    if (rawScale is List) {
      for (var item in rawScale) {
        if (item != null) {
          scaleList.add(item.toString());
        }
      }
    }
    return Event(
      id: doc.id,
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      attendees: attendeesList,
      scaleAttendees: scaleList,
    );
  }
}

class CalendarioNovo extends StatefulWidget {
  const CalendarioNovo({super.key});

  @override
  State<CalendarioNovo> createState() => _CalendarioNovoState();
}

class _CalendarioNovoState extends State<CalendarioNovo> {
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Event>> _events = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Color> _eventColors = {
    'Rito Aberto': Colors.green,
    'Rito Fechado': Colors.red,
    'Festa': Colors.orange,
    'Curso': Colors.teal,
    'Limpeza': Colors.blue,
    'Aniversário': Colors.purple
  };

  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Simula permissão de usuários “adi”

  // Campos para criação de novo evento
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  String? _newEventType;
  DateTime? _newEventDate;
  String? _selectedBirthdayChild;

  // Lista de tipos de evento
  final List<String> _eventTypes = [
    'Rito Aberto',
    'Rito Fechado',
    'Festa',
    'Curso',
    'Limpeza',
    'Aniversário',
  ];

  Future<List<String>> _getAllUserTokens() async {
    final snaps = await _firestore.collection('Usuarios').get();
    return snaps.docs
        .map((d) => (d.data())['fcm_token'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<String?> _getUserToken(String nome) async {
    final doc = await _firestore.collection('Usuarios').doc(nome).get();
    return (doc.data())?['fcm_token'] as String?;
  }

  Future<List<String>> _getAdminTokens() async {
    // Busca apenas usuários com função 'administrador' e token não vazio
    QuerySnapshot adminSnapshot = await _firestore
        .collection('Usuarios')
        .where('funcao', isEqualTo: 'administrador')
        .where('fcm_token', isNotEqualTo: '')
        .get();
    return adminSnapshot.docs
        .map((d) => (d.data() as Map<String, dynamic>)['fcm_token'] as String?)
        .whereType<String>()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Listen to Firestore events collection
    _firestore.collection('events').snapshots().listen((snapshot) {
      final Map<DateTime, List<Event>> eventsMap = {};
      for (var doc in snapshot.docs) {
        final event = Event.fromDoc(doc);
        final key = DateTime(event.date.year, event.date.month, event.date.day);
        eventsMap.putIfAbsent(key, () => []).add(event);
      }
      setState(() {
        _events = eventsMap;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('Usuarios')
          .where('funcao', isEqualTo: 'administrador')
          .where('fcm_token', isNotEqualTo: '')
          .get(),
      builder: (context, snapshot) {
        final nomeUsuarioLogado =
            ModalRoute.of(context)!.settings.arguments as String?;
        final isAdmin = snapshot.hasData &&
            snapshot.data!.docs.any((doc) => doc.id == nomeUsuarioLogado);
        // Filtra eventos do mês selecionado
        final monthEvents = _events.entries
            .where((e) =>
                e.key.year == _selectedDate.year &&
                e.key.month == _selectedDate.month)
            .toList()
          ..sort((a, b) => a.key.day.compareTo(b.key.day));
        // Eventos do dia selecionado
        final List<Event> dayEvents = _events[DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            )] ??
            <Event>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendário'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Legenda de cores',
                onPressed: _showEventLegend,
              ),
            ],
          ),
          body: Column(
            children: [
              TableCalendar<Event>(
                firstDay: DateTime(1900),
                lastDay: DateTime(2100),
                locale: 'pt_BR',
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mês',
                  CalendarFormat.twoWeeks: '2 Semanas',
                  CalendarFormat.week: 'Semana',
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleTextFormatter: (date, locale) {
                    // formata "abril 2025"
                    final lower = DateFormat.yMMMM(locale).format(date);
                    // capitaliza a primeira letra e mantem o restante
                    return '${lower[0].toUpperCase()}${lower.substring(1)}';
                  },
                ),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                eventLoader: (day) =>
                    _events[DateTime(day.year, day.month, day.day)] ??
                    <Event>[],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                calendarStyle: const CalendarStyle(),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Wrap(
                        spacing: 4.0,
                        children: events.map((event) {
                          final color = _eventColors[event.type] ?? Colors.grey;
                          return Container(
                            width: 7.0,
                            height: 7.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          );
                        }).toList(),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: dayEvents.isNotEmpty
                    ? ListView.builder(
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) {
                          final event = dayEvents[index];
                          // Chave baseada no título + índice para unicidade
                          final dismissKey = ValueKey('${event.title}_$index');
                          final dateKey = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                          );

                          final hasConfirmed = nomeUsuarioLogado != null &&
                              event.attendees.contains(nomeUsuarioLogado);

                          if (isAdmin) {
                            return Dismissible(
                              key: dismissKey,
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) async {
                                await _firestore
                                    .collection('events')
                                    .doc(event.id)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Evento removido')),
                                );
                                final tokens = await _getAllUserTokens();
                                for (var token in tokens) {
                                  sendFCMMessage(
                                    'Evento cancelado: ${event.title}',
                                    'Evento Cancelado',
                                    token,
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(event.title),
                                  ),
                                  if (event.type == 'Aniversário' &&
                                      DateTime.now().year == event.date.year &&
                                      DateTime.now().month ==
                                          event.date.month &&
                                      DateTime.now().day == event.date.day)
                                    TextButton(
                                      onPressed: () async {
                                        final doc = await _firestore
                                            .collection('events')
                                            .doc(event.id)
                                            .get();
                                        final aniversariante =
                                            doc['aniversariante'];
                                        final token =
                                            await _getUserToken(aniversariante);
                                        if (token != null) {
                                          sendFCMMessage(
                                            'Parabéns pelo seu aniversário!',
                                            'Feliz Aniversário',
                                            token,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Parabéns enviado com sucesso!')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Token não encontrado para o aniversariante.')),
                                          );
                                        }
                                      },
                                      child: const Text('Mandar parabéns'),
                                    ),
                                  if (event.type == 'Limpeza') ...[
                                    if (isAdmin)
                                      TextButton(
                                        onPressed: () => _openScaleSheet(event),
                                        child: const Text('Adicionar à escala'),
                                      ),
                                  ] else ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        TextButton(
                                          onPressed: () async {
                                            if (nomeUsuarioLogado == null) {
                                              return;
                                            }
                                            final docRef = _firestore
                                                .collection('events')
                                                .doc(event.id);
                                            if (hasConfirmed) {
                                              await docRef.update({
                                                'attendees':
                                                    FieldValue.arrayRemove(
                                                        [nomeUsuarioLogado])
                                              });
                                            } else {
                                              await docRef.update({
                                                'attendees':
                                                    FieldValue.arrayUnion(
                                                        [nomeUsuarioLogado])
                                              });
                                            }
                                            final adminTokens =
                                                await _getAdminTokens();
                                            for (var token in adminTokens) {
                                              sendFCMMessage(
                                                '$nomeUsuarioLogado ${hasConfirmed ? 'removeu' : 'confirmou'} presença em rito ${event.title} no dia ${event.date.day}/${event.date.month}/${event.date.year}',
                                                'Presença Atualizada',
                                                token,
                                              );
                                            }
                                          },
                                          child: Text(hasConfirmed
                                              ? 'Remover presença'
                                              : 'Confirmar presença'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) {
                                                if (event.attendees.isEmpty) {
                                                  return const Padding(
                                                    padding: EdgeInsets.all(16),
                                                    child: Center(
                                                        child: Text(
                                                            'Nenhum filho confirmou presença ainda')),
                                                  );
                                                }
                                                return ListView(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  children: event.attendees
                                                      .map((name) => ListTile(
                                                            title: Text(name),
                                                          ))
                                                      .toList(),
                                                );
                                              },
                                            );
                                          },
                                          child: const Text('Exibir presenças'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(event.title),
                                ),
                                if (event.type == 'Limpeza') ...[
                                  if (isAdmin)
                                    TextButton(
                                      onPressed: () => _openScaleSheet(event),
                                      child: const Text('Adicionar à escala'),
                                    ),
                                ] else ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          if (nomeUsuarioLogado == null) return;
                                          final docRef = _firestore
                                              .collection('events')
                                              .doc(event.id);
                                          if (hasConfirmed) {
                                            await docRef.update({
                                              'attendees':
                                                  FieldValue.arrayRemove(
                                                      [nomeUsuarioLogado])
                                            });
                                          } else {
                                            await docRef.update({
                                              'attendees':
                                                  FieldValue.arrayUnion(
                                                      [nomeUsuarioLogado])
                                            });
                                          }
                                          final adminTokens =
                                              await _getAdminTokens();
                                          for (var token in adminTokens) {
                                            sendFCMMessage(
                                              '$nomeUsuarioLogado ${hasConfirmed ? 'removeu' : 'confirmou'} presença em rito ${event.title} no dia ${event.date.day}/${event.date.month}/${event.date.year}',
                                              'Presença Atualizada',
                                              token,
                                            );
                                          }
                                        },
                                        child: Text(hasConfirmed
                                            ? 'Remover presença'
                                            : 'Confirmar presença'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) {
                                              if (event.attendees.isEmpty) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Center(
                                                      child: Text(
                                                          'Nenhum filho confirmou presença ainda')),
                                                );
                                              }
                                              return ListView(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                children: event.attendees
                                                    .map((name) => ListTile(
                                                          title: Text(name),
                                                        ))
                                                    .toList(),
                                              );
                                            },
                                          );
                                        },
                                        child: const Text('Exibir presenças'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          }
                        },
                      )
                    : const Center(child: Text('Nenhum evento neste mês')),
              ),
            ],
          ),
          floatingActionButton: isAdmin
              ? SafeArea(
                  bottom: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 25.0, right: 5.0),
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      heroTag: 'calendaradd',
                      shape: const CircleBorder(
                        side: BorderSide(color: kPrimaryColor),
                      ),
                      onPressed: _openAddEventDialog,
                      child: const Icon(Icons.add, color: kPrimaryColor),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _openAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        _newEventDate = _selectedDate;
        _newEventType = _eventTypes.first;
        _titleController.clear();
        _dayController.text = _selectedDate.day.toString();
        _monthController.text = _selectedDate.month.toString();
        _yearController.text = _selectedDate.year.toString();
        return AlertDialog(
          title: const Text('Novo Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _newEventType,
                  items: _eventTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _newEventType = val),
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dayController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Dia',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _monthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Mês',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ano',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (_newEventType == 'Aniversário')
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('Usuarios').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final filhos = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            value: _selectedBirthdayChild,
                            items: filhos.map((doc) {
                              final nome = doc.id;
                              return DropdownMenuItem(
                                  value: nome, child: Text(nome));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedBirthdayChild = val),
                            decoration: InputDecoration(
                              labelText: 'Selecionar aniversariante',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final day = int.tryParse(_dayController.text);
                final month = int.tryParse(_monthController.text);
                final year = int.tryParse(_yearController.text);
                final title = _titleController.text;
                final type = _newEventType;

                if (day != null &&
                    month != null &&
                    year != null &&
                    title.isNotEmpty &&
                    type != null) {
                  // 1) Cria o DateTime do evento
                  final eventDate = DateTime(year, month, day);

                  // 2) Grava no Firestore e recupera o ID
                  final docRef = await _firestore.collection('events').add({
                    'type': type,
                    'title': title,
                    'date': Timestamp.fromDate(eventDate),
                    'attendees': <String>[],
                    if (type == 'Aniversário')
                      'aniversariante': _selectedBirthdayChild,
                  });
                  final tokens = await _getAllUserTokens();
                  for (var token in tokens) {
                    sendFCMMessage(
                      'Novo evento: $title em $day/$month/$year',
                      'Novo Evento',
                      token,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showEventLegend() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Legenda de Cores'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _eventColors.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _openScaleSheet(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _buildScaleSheetContent(event),
    );
  }

  Widget _buildScaleSheetContent(Event event) {
    List<String> selected = List<String>.from(event.scaleAttendees);
    return StatefulBuilder(
      builder: (context, setStateSheet) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('Usuarios').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      return ListView(
                        children: docs.map((doc) {
                          final name = (doc.data()
                                  as Map<String, dynamic>)['nome'] as String? ??
                              '';
                          final isChecked = selected.contains(name);
                          return CheckboxListTile(
                            title: Text(name),
                            value: isChecked,
                            onChanged: (val) {
                              setStateSheet(() {
                                if (val == true) {
                                  selected.add(name);
                                } else {
                                  selected.remove(name);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final docRef =
                        _firestore.collection('events').doc(event.id);
                    // Determine additions and removals
                    final toAdd = selected
                        .where((name) => !event.scaleAttendees.contains(name))
                        .toList();
                    final toRemove = event.scaleAttendees
                        .where((name) => !selected.contains(name))
                        .toList();
                    if (toAdd.isNotEmpty) {
                      await docRef.update(
                          {'scaleAttendees': FieldValue.arrayUnion(toAdd)});
                    }
                    if (toRemove.isNotEmpty) {
                      await docRef.update(
                          {'scaleAttendees': FieldValue.arrayRemove(toRemove)});
                    }
                    for (var name in toAdd) {
                      final token = await _getUserToken(name);
                      if (token != null) {
                        sendFCMMessage(
                          'Você foi escalado para limpeza em ${event.date.day}/${event.date.month}/${event.date.year}',
                          'Escala de Limpeza',
                          token,
                        );
                      }
                    }
                    for (var name in toRemove) {
                      final token = await _getUserToken(name);
                      if (token != null) {
                        sendFCMMessage(
                          'Você foi removido da escala de limpeza em ${event.date.day}/${event.date.month}/${event.date.year}',
                          'Escala de Limpeza',
                          token,
                        );
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar escala'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
