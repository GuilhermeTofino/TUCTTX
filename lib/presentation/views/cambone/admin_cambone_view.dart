import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/service_locator.dart';
import '../../viewmodels/cambone/cambone_viewmodel.dart';
import '../../widgets/custom_logo_loader.dart';
import '../../widgets/premium_sliver_app_bar.dart';

import '../../../domain/models/cambone_model.dart';
import '../../../domain/models/work_event_model.dart'; // Added // Added import

class AdminCamboneView extends StatefulWidget {
  final CamboneSchedule? scheduleToEdit; // Added argument

  const AdminCamboneView({super.key, this.scheduleToEdit});

  @override
  State<AdminCamboneView> createState() => _AdminCamboneViewState();
}

class _AdminCamboneViewState extends State<AdminCamboneView> {
  final _viewModel = getIt<CamboneViewModel>();
  final _textController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    // Garante que a lista de eventos esteja atualizada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchUpcomingEvents(AppConfig.instance.tenant.tenantSlug);
    });

    if (widget.scheduleToEdit != null) {
      _viewModel.loadForEdit(widget.scheduleToEdit!);
    } else {
      _viewModel.clearPreview();
    }
  }

  @override
  void dispose() {
    _viewModel.clearPreview();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const PremiumSliverAppBar(
            title: "Importar Escala (IA)",
            backgroundIcon: Icons.edit_calendar_rounded,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seletor de Evento Substitui Data
                  _buildEventSelector(tenant),
                  const SizedBox(height: 24),
                  _buildInputSection(tenant),
                  const SizedBox(height: 32),
                  const Text(
                    "Pré-visualização da Escala",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading &&
                  _viewModel.previewAssignments.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CustomLogoLoader()),
                );
              }

              if (_viewModel.previewAssignments.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "Nenhum dado importado ainda.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final assignment = _viewModel.previewAssignments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildPreviewCard(assignment, index, tenant),
                  );
                }, childCount: _viewModel.previewAssignments.length),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildActionButtons(tenant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector(tenant) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // Se estiver carregando eventos e não tiver nenhum ainda
        if (_viewModel.availableEvents.isEmpty && _viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  "Selecionar Evento",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<WorkEvent>(
                  value: _viewModel.selectedEvent,
                  hint: const Text("Selecione um evento..."),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: tenant.primaryColor),
                  items: _viewModel.availableEvents.map((event) {
                    final dateStr = DateFormat(
                      "dd/MM",
                      'pt_BR',
                    ).format(event.date);
                    return DropdownMenuItem<WorkEvent>(
                      value: event,
                      child: Text(
                        "${event.title} - $dateStr",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (WorkEvent? newValue) {
                    _viewModel.selectEvent(newValue);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputSection(tenant) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Cole o texto da escala aqui...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _viewModel.importFromText(_textController.text),
                icon: const Icon(Icons.text_fields),
                label: const Text("Processar Texto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tenant.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("Ler Foto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: tenant.primaryColor,
                  elevation: 0,
                  side: BorderSide(color: tenant.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      _viewModel.importFromImage(File(image.path));
    }
  }

  Widget _buildPreviewCard(assignment, int index, tenant) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) {
        // Aceita se vier de outro card (index diferente)
        return data != null && data['sourceIndex'] != index;
      },
      onAccept: (data) {
        final mediumName = data['medium'] as String;
        final sourceIndex = data['sourceIndex'] as int;
        _viewModel.moveMedium(mediumName, sourceIndex, index);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? tenant.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? tenant.primaryColor
                  : Colors.grey[200]!,
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.camboneName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: tenant.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignment.mediums.map<Widget>((mediumName) {
                  return LongPressDraggable<Map<String, dynamic>>(
                    data: {'medium': mediumName, 'sourceIndex': index},
                    feedback: Material(
                      color: Colors.transparent,
                      child: Chip(
                        label: Text(mediumName),
                        backgroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Chip(
                        label: Text(mediumName),
                        backgroundColor: Colors.grey[100],
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    child: Chip(
                      label: Text(mediumName),
                      backgroundColor: Colors.grey[100],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(tenant) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.previewAssignments.isEmpty)
          return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // Data passada é ignorada pelo VM em favor do evento selecionado
              await _viewModel.saveSchedule(DateTime.now(), tenant.tenantSlug);
              if (context.mounted && _viewModel.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Escala salva com sucesso!")),
                );
                Navigator.pop(context);
              } else if (mounted && _viewModel.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro: ${_viewModel.error}")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Salvar Escala",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
