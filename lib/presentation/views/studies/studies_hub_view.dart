import 'package:app_tenda/presentation/viewmodels/studies/study_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../widgets/premium_sliver_app_bar.dart';
import 'documents_list_view.dart';

class StudiesHubView extends StatefulWidget {
  const StudiesHubView({super.key});

  @override
  State<StudiesHubView> createState() => _StudiesHubViewState();
}

class _StudiesHubViewState extends State<StudiesHubView> {
  final StudyViewModel _viewModel = getIt<StudyViewModel>();

  final List<Map<String, dynamic>> studyOptions = [
    {
      'id': 'apostila',
      'title': 'Apostila',
      'subtitle': 'Conteúdo doutrinário',
      'icon': Icons.menu_book_rounded,
      'color': Colors.blue,
      'isSingle': true,
    },
    {
      'id': 'rumbe',
      'title': 'Rumbê',
      'subtitle': 'Regras da casa',
      'icon': Icons.gavel_rounded,
      'color': Colors.brown,
      'isSingle': true,
    },
    {
      'id': 'pontos_cantados',
      'title': 'Pontos Cantados',
      'subtitle': 'Letras e áudios',
      'icon': Icons.music_note_rounded,
      'color': Colors.orange,
      'isSingle': true,
    },
    {
      'id': 'pontos_riscados',
      'title': 'Pontos Riscados',
      'subtitle': 'Símbolos sagrados',
      'icon': Icons.draw_rounded,
      'color': Colors.red,
      'isSingle': true,
    },
    {
      'id': 'faq',
      'title': 'FAQ',
      'subtitle': 'Dúvidas frequentes',
      'icon': Icons.quiz_rounded,
      'color': Colors.teal,
      'isSingle': false,
    },
    {
      'id': 'ervas',
      'title': 'Ervas',
      'subtitle': 'Guia de banhos e defumação',
      'icon': Icons.eco_rounded,
      'color': Colors.green,
      'isSingle': false,
    },
    {
      'id': 'biblioteca',
      'title': 'Biblioteca',
      'subtitle': 'Arquivos e PDFs',
      'icon': Icons.library_books_rounded,
      'color': Colors.indigo,
      'isSingle': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          const PremiumSliverAppBar(
            title: 'Estudos',
            backgroundIcon: Icons.school_rounded,
            expandedHeight: 180,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final option = studyOptions[index];
                return _buildStudyCard(context, option);
              }, childCount: studyOptions.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStudyCard(BuildContext context, Map<String, dynamic> option) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleTopicTap(option),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: option['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(option['icon'], color: option['color'], size: 28),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option['subtitle'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTopicTap(Map<String, dynamic> option) {
    print(
      'Clicou no tópico de estudo: ${option['title']} (ID: ${option['id']})',
    );
    if (option['isSingle'] == true) {
      // Para tópicos de documento único, buscamos o primeiro da lista
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      _viewModel
          .getDocumentsStream(option['id'])
          .first
          .then((list) {
            if (mounted) Navigator.pop(context); // Fecha o loading

            if (list.isNotEmpty) {
              _openPdf(list.first.fileUrl);
            } else {
              print('Este documento ainda não foi publicado.');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Este documento ainda não foi publicado.'),
                ),
              );
            }
          })
          .catchError((e) {
            if (mounted) Navigator.pop(context);
            print('Erro ao carregar: $e');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
          });
    } else {
      // Para hubs, navegamos para a lista de documentos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentsListView(
            topicId: option['id'],
            topicTitle: option['title'],
          ),
        ),
      );
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        print('Não foi possível abrir o PDF.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o PDF.')),
        );
      }
    }
  }
}
