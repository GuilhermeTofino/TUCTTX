import 'dart:io';
import 'package:app_tenda/presentation/viewmodels/studies/study_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/models/study_document_model.dart';
import '../../widgets/premium_sliver_app_bar.dart';
import '../../widgets/custom_logo_loader.dart';

class AdminStudiesView extends StatefulWidget {
  const AdminStudiesView({super.key});

  @override
  State<AdminStudiesView> createState() => _AdminStudiesViewState();
}

class _AdminStudiesViewState extends State<AdminStudiesView> {
  final StudyViewModel _viewModel = getIt<StudyViewModel>();
  String _selectedTopicId = 'biblioteca';

  final List<Map<String, dynamic>> _topics = [
    {'id': 'apostila', 'title': 'Apostila', 'icon': Icons.menu_book_rounded},
    {'id': 'rumbe', 'title': 'Rumbê', 'icon': Icons.gavel_rounded},
    {
      'id': 'pontos_cantados',
      'title': 'P. Cantados',
      'icon': Icons.music_note_rounded,
    },
    {
      'id': 'pontos_riscados',
      'title': 'P. Riscados',
      'icon': Icons.draw_rounded,
    },
    {'id': 'faq', 'title': 'FAQ', 'icon': Icons.quiz_rounded},
    {'id': 'ervas', 'title': 'Ervas', 'icon': Icons.eco_rounded},
    {
      'id': 'biblioteca',
      'title': 'Biblioteca',
      'icon': Icons.library_books_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              CustomScrollView(
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
              ),
              if (_viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CustomLogoLoader(size: 100, logoSize: 50),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Novo PDF",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConfig.instance.tenant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildTopicSelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            final isSelected = _selectedTopicId == topic['id'];
            final primaryColor = AppConfig.instance.tenant.primaryColor;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedTopicId = topic['id']!),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        topic['icon'],
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        topic['title']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Nenhum PDF neste tópico",
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  doc.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(doc.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteConfirmation(doc),
                  ),
                ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Novo Documento",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Preencha as informações para o upload",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Título do Documento",
                    hintText: "Ex: Apostila de Ervas",
                    prefixIcon: const Icon(Icons.title_rounded),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: selectedFile != null
                          ? Colors.green[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedFile != null
                            ? Colors.green[200]!
                            : Colors.blue[200]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          selectedFile != null
                              ? Icons.check_circle_rounded
                              : Icons.attach_file_rounded,
                          color: selectedFile != null
                              ? Colors.green
                              : Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedFile == null
                              ? "Selecionar PDF"
                              : selectedFile!.path.split('/').last,
                          style: TextStyle(
                            color: selectedFile != null
                                ? Colors.green[700]
                                : Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isEmpty || selectedFile == null)
                        return;
                      Navigator.pop(context);
                      _upload(titleController.text, selectedFile!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.instance.tenant.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Iniciar Upload",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          SnackBar(
            content: const Text("Upload concluído com sucesso!"),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro no upload: $e"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(StudyDocumentModel doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Excluir Documento?"),
        content: Text(
          "Confirma a exclusão de '${doc.title}'? Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey[600])),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _viewModel.deleteDocument(doc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Excluir"),
            ),
          ),
        ],
      ),
    );
  }
}
