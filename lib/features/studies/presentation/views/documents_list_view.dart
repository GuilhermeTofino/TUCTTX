import 'package:app_tenda/presentation/viewmodels/studies/study_viewmodel.dart'
    show StudyViewModel;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/models/study_document_model.dart';
import '../../widgets/premium_sliver_app_bar.dart';

class DocumentsListView extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const DocumentsListView({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<DocumentsListView> createState() => _DocumentsListViewState();
}

class _DocumentsListViewState extends State<DocumentsListView> {
  final StudyViewModel _viewModel = getIt<StudyViewModel>();
  String? _currentFolder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<List<StudyDocumentModel>>(
        stream: _viewModel.getDocumentsStream(widget.topicId),
        builder: (context, snapshot) {
          final allDocs = snapshot.data ?? [];

          // Logic to filter docs and folders
          List<StudyDocumentModel> visibleDocs;
          List<String> visibleFolders = [];

          if (_currentFolder == null) {
            // Root view: Show folders and root files
            visibleFolders =
                allDocs
                    .map((d) => d.folder)
                    .where((f) => f != null && f.isNotEmpty)
                    .map((f) => f!)
                    .toSet()
                    .toList()
                  ..sort();

            visibleDocs = allDocs
                .where((d) => d.folder == null || d.folder!.trim().isEmpty)
                .toList();
          } else {
            // Folder view: Show only files in this folder
            visibleDocs = allDocs
                .where((d) => d.folder == _currentFolder)
                .toList();
          }

          // Separate loading/empty states from main content
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allDocs.isEmpty) {
            return CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: widget.topicTitle,
                  backgroundIcon: Icons.library_books_rounded,
                ),
                _buildEmptyState(),
              ],
            );
          }

          return WillPopScope(
            onWillPop: () async {
              if (_currentFolder != null) {
                setState(() => _currentFolder = null);
                return false;
              }
              return true;
            },
            child: CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _currentFolder ?? widget.topicTitle,
                  backgroundIcon: _currentFolder != null
                      ? Icons.folder_open_rounded
                      : Icons.library_books_rounded,
                  leading: _currentFolder != null
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              setState(() => _currentFolder = null),
                        )
                      : null, // Default back button
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      // Render Folders first
                      if (index < visibleFolders.length) {
                        return _buildFolderCard(visibleFolders[index]);
                      }
                      // Render Docs after
                      final docIndex = index - visibleFolders.length;
                      return _buildDocumentCard(visibleDocs[docIndex]);
                    }, childCount: visibleFolders.length + visibleDocs.length),
                  ),
                ),
                if (visibleFolders.isEmpty && visibleDocs.isEmpty)
                  _buildEmptyFolderState(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(String folderName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_rounded, color: Colors.blue),
          ),
          title: Text(
            folderName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => setState(() => _currentFolder = folderName),
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
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Nenhum documento encontrado",
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFolderState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Pasta vazia",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(StudyDocumentModel doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
          ),
          title: Text(
            doc.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormat('dd/MM/yyyy').format(doc.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => _openPdf(doc.fileUrl),
        ),
      ),
    );
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o PDF.')),
        );
      }
    }
  }
}
