import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/di/service_locator.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/custom_logo_loader.dart';
import 'import_events_view.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final _viewModel = getIt<CalendarViewModel>();
  final _authVM = getIt<RegisterViewModel>();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _viewModel.loadEvents(AppConfig.instance.tenant.tenantSlug);
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // Trava lógica: O botão só é renderizado se o usuário logado for admin
      floatingActionButton: _authVM.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportEventsView(),
                  ),
                );
                _loadEvents();
              },
              backgroundColor: tenant.primaryColor,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
      body: Column(
        children: [
          _buildHeader(tenant),
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const Center(child: CustomLogoLoader());
                }

                // Filtragem por mês selecionado
                final filteredEvents = _viewModel.events
                    .where(
                      (e) =>
                          e.date.month == _selectedMonth.month &&
                          e.date.year == _selectedMonth.year,
                    )
                    .toList();

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: filteredEvents.isEmpty
                      ? _buildEmptyState()
                      : _buildAnimatedList(filteredEvents, tenant),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(tenant) {
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        color: tenant.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 10),
          const Text(
            "Cronograma",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Giras e trabalhos do terreiro",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 25),

          // Seletor de Mês com Animação de Texto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(
                    Icons.keyboard_arrow_left,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    monthLabel[0].toUpperCase() + monthLabel.substring(1),
                    key: ValueKey(monthLabel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedList(List filteredEvents, tenant) {
    return ListView.builder(
      key: ValueKey(_selectedMonth),
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 1.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value * 50),
              child: Opacity(
                opacity: (1.0 - value).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _buildEventCard(event, tenant),
        );
      },
    );
  }

  Widget _buildEventCard(event, tenant) {
    final dayStr = DateFormat('dd').format(event.date);
    final monthStr = DateFormat(
      'MMM',
      'pt_BR',
    ).format(event.date).toUpperCase().replaceAll('.', '');
    final timeStr = DateFormat('HH:mm').format(event.date);

    return GestureDetector(
      onTap: () => _showEventDetailsBottomSheet(event, tenant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: event.type == 'Pública'
                      ? Colors.green
                      : tenant.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayStr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: tenant.primaryColor,
                      ),
                    ),
                    Text(
                      monthStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, indent: 20, endIndent: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$timeStr - ${event.type}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetailsBottomSheet(event, tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _viewModel.getConfirmations(tenant.tenantSlug, event.id),
            builder: (context, snapshot) {
              final attendees = snapshot.data ?? [];
              final currentUser = _authVM.currentUser;
              final isConfirmed =
                  currentUser != null &&
                  attendees.any((a) => a['id'] == currentUser.id);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tenant.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.event_note,
                          color: tenant.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                "EEEE, d 'de' MMMM",
                                'pt_BR',
                              ).format(event.date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.access_time,
                    "Horário",
                    DateFormat('HH:mm').format(event.date),
                  ),
                  _buildDetailRow(Icons.label_outline, "Tipo", event.type),
                  // Seção de Faxina (Nova)
                  if (event.cleaningCrew != null &&
                      event.cleaningCrew!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.cleaning_services_outlined,
                          color: tenant.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Equipe de Faxina",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.cleaningCrew!.map<Widget>((name) {
                        return Chip(
                          label: Text(name),
                          backgroundColor:
                              Colors.blue[50], // Azul clarinho para diferenciar
                          labelStyle: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                          avatar: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    const Text(
                      "Detalhes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  // Seção de Presença
                  _buildAttendanceSection(
                    event,
                    attendees,
                    tenant,
                    currentUser,
                    isConfirmed,
                  ),

                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSection(
    event,
    List<Map<String, dynamic>> attendees,
    tenant,
    currentUser,
    bool isConfirmed,
  ) {
    if (currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Presença (${attendees.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (isConfirmed) {
                  _viewModel.removePresence(
                    tenant.tenantSlug,
                    event.id,
                    currentUser.id,
                  );
                } else {
                  _viewModel.confirmPresence(
                    tenant.tenantSlug,
                    event.id,
                    currentUser,
                  );
                }
              },
              icon: Icon(
                isConfirmed ? Icons.close : Icons.check,
                size: 18,
                color: isConfirmed ? Colors.red : Colors.white,
              ),
              label: Text(
                isConfirmed ? "Não vou" : "Vou",
                style: TextStyle(
                  color: isConfirmed ? Colors.red : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConfirmed
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green,
                elevation: isConfirmed ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (attendees.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: attendees.length,
              itemBuilder: (context, index) {
                final attendee = attendees[index];
                final name = attendee['name'] ?? 'Filho';
                final firstName = name.split(' ').first;
                final photoUrl = attendee['photoUrl'];

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                firstName[0].toUpperCase(),
                                style: TextStyle(
                                  color: tenant.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        firstName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Text(
              "Nenhum filho confirmou presença ainda.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 22),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma gira para este mês",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
