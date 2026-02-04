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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<List<StudyDocumentModel>>(
        stream: _viewModel.getDocumentsStream(widget.topicId),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              PremiumSliverAppBar(
                title: widget.topicTitle,
                backgroundIcon: Icons.library_books_rounded,
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                _buildEmptyState()
              else
                _buildDocumentList(snapshot.data!),
            ],
          );
        },
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

  Widget _buildDocumentList(List<StudyDocumentModel> documents) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = documents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDocumentCard(doc),
          );
        }, childCount: documents.length),
      ),
    );
  }

  Widget _buildDocumentCard(StudyDocumentModel doc) {
    return Container(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
