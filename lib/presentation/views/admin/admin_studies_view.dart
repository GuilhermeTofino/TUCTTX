import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/models/study_document_model.dart';
import '../../viewmodels/study_viewmodel.dart';
import '../../widgets/premium_sliver_app_bar.dart';

class AdminStudiesView extends StatefulWidget {
  const AdminStudiesView({super.key});

  @override
  State<AdminStudiesView> createState() => _AdminStudiesViewState();
}

class _AdminStudiesViewState extends State<AdminStudiesView> {
  final StudyViewModel _viewModel = getIt<StudyViewModel>();
  String _selectedTopicId = 'biblioteca';

  final List<Map<String, String>> _topics = [
    {'id': 'apostila', 'title': 'Apostila'},
    {'id': 'rumbe', 'title': 'Rumbê'},
    {'id': 'pontos_cantados', 'title': 'Pontos Cantados'},
    {'id': 'pontos_riscados', 'title': 'Pontos Riscados'},
    {'id': 'faq', 'title': 'FAQ'},
    {'id': 'ervas', 'title': 'Ervas'},
    {'id': 'biblioteca', 'title': 'Biblioteca'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              const PremiumSliverAppBar(
                title: "Gerenciar Estudos",
                backgroundIcon: Icons.library_books_rounded,
              ),
              _buildTopicSelector(),
              StreamBuilder<List<StudyDocumentModel>>(
                stream: _viewModel.getDocumentsStream(_selectedTopicId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data ?? [];
                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildDocumentList(docs);
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSheet,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text("Novo PDF"),
        backgroundColor: AppConfig.instance.tenant.primaryColor,
      ),
    );
  }

  Widget _buildTopicSelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            final isSelected = _selectedTopicId == topic['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                selected: isSelected,
                label: Text(topic['title']!),
                onSelected: (val) {
                  setState(() => _selectedTopicId = topic['id']!);
                },
                selectedColor: AppConfig.instance.tenant.primaryColor
                    .withOpacity(0.2),
                checkmarkColor: AppConfig.instance.tenant.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppConfig.instance.tenant.primaryColor
                      : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Nenhum PDF neste tópico",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(List<StudyDocumentModel> docs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = docs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(
                doc.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(doc.createdAt)),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: () => _showDeleteConfirmation(doc),
              ),
            ),
          );
        }, childCount: docs.length),
      ),
    );
  }

  void _showUploadSheet() {
    final titleController = TextEditingController();
    File? selectedFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Upload de Documento",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Título do Documento",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );
                    if (result != null) {
                      setModalState(
                        () => selectedFile = File(result.files.single.path!),
                      );
                    }
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(
                    selectedFile == null
                        ? "Selecionar PDF"
                        : "Arquivo Selecionado",
                  ),
                ),
                if (selectedFile != null)
                  Text(
                    selectedFile!.path.split('/').last,
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty || selectedFile == null)
                        return;

                      Navigator.pop(context);
                      _upload(titleController.text, selectedFile!);
                    },
                    child: const Text("Fazer Upload"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _upload(String title, File file) async {
    try {
      await _viewModel.uploadPdf(
        topicId: _selectedTopicId,
        title: title,
        file: file,
        authorId: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload concluído com sucesso!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro no upload: $e")));
      }
    }
  }

  void _showDeleteConfirmation(StudyDocumentModel doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Documento?"),
        content: Text("Confirma a exclusão de '${doc.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _viewModel.deleteDocument(doc);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }
}
