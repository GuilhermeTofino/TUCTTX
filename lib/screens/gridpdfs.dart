import 'dart:io';
import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/widgets/custom_loader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_tenda/data/storage.dart';
import 'package:app_tenda/entrar.dart';
import 'package:app_tenda/vizualizador_pdf.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class GridFilesFromFolder extends StatefulWidget {
  final String folderName;

  const GridFilesFromFolder({super.key, required this.folderName});

  @override
  State<GridFilesFromFolder> createState() => _GridFilesFromFolderState();
}

class _GridFilesFromFolderState extends State<GridFilesFromFolder> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Reference> files = [];
  List<Reference> filteredFiles = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadFilesFromFolder();
  }

  Future<void> _loadFilesFromFolder() async {
    try {
      final storageService = StorageService();
      final result = await storageService.listFilesInFolder(widget.folderName);
      setState(() {
        files = result;
        filteredFiles = result;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar arquivos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterFiles(String query) {
    final filtered = files
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      filteredFiles = filtered;
    });
  }

  Future<void> _uploadFileToStorage(File file, String path) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: TucttxLoader()),
      );

      final ref = _storage.ref().child(path);
      await ref.putFile(file);

      Navigator.pop(context); // fecha o loader
      // await sendFCMToAll('Arquivo enviado',
      //     'O arquivo "$path" foi adicionado no aplicativo para estudos.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload concluído: $path')),
      );
      _loadFilesFromFolder();
    } catch (e) {
      Navigator.pop(context); // fecha o loader se der erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer upload: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _handleUpload,
                ),
              ]
            : [],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredFiles.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum arquivo salvo.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Pesquisar arquivos',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: _filterFiles,
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredFiles.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final file = filteredFiles[index];

                            return ListTile(
                              leading: FutureBuilder<Uint8List?>(
                                future: file.getData(1024 * 100), // tenta obter os primeiros 100KB
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done &&
                                      snapshot.hasData &&
                                      snapshot.data != null) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 40,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    );
                                  } else {
                                    return const Icon(Icons.picture_as_pdf, color: Colors.red);
                                  }
                                },
                              ),
                              title: Text(file.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () async {
                                      final url = await file.getDownloadURL();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PDFViewerScreen(
                                              url: url, nomeArquivo: file.name),
                                        ),
                                      );
                                    },
                                  ),
                                  if (isAdmin)
                                    IconButton(
                                      icon:
                                          const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final storageService = StorageService();
                                        await storageService
                                            .deleteFile(file.fullPath);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Arquivo deletado: ${file.name}')),
                                        );
                                        _loadFilesFromFolder(); // Atualiza a lista após exclusão
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: null,
    );
  }
  void _handleUpload() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: TucttxLoader()),
    );

    final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf']);

    Navigator.pop(context); // Fecha o loader após selecionar

    if (pickedFile == null || pickedFile.files.single.path == null) {
      return;
    }

    final file = File(pickedFile.files.single.path!);
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome do Arquivo'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Digite o nome do arquivo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final fileName = nameController.text.trim();
                if (fileName.isEmpty) return;
                Navigator.pop(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: TucttxLoader()),
                );

                await _uploadFileToStorage(
                  file,
                  '${widget.folderName}/$fileName',
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}