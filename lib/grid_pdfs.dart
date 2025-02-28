import 'dart:convert';
import 'dart:io';

import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/entrar.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_tenda/vizualizador_pdf.dart';

class ListaPdf extends StatefulWidget {
  final String appBarTitle;

  const ListaPdf({
    super.key,
    required this.appBarTitle,
  });

  @override
  State<ListaPdf> createState() => _ListaPdfState();
}

class _ListaPdfState extends State<ListaPdf> {
  bool _mostrarGrid = false;
  bool _leituraConfirmada = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarEstado();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("Documentos")
          .doc(widget.appBarTitle)
          .collection("Arquivos")
          .get();

      setState(() {
        _documents = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'title': data['nome'] as String,
            'base64': data['base64'] as String,
            'fileName': data['nome_arquivo'] as String,
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading documents: $e");
      // Handle error, e.g., show a snackbar
    }
  }

  Future<void> _inicializarEstado() async {
    if (widget.appBarTitle == 'Ervas' && !isAdmin) {
      await _verificarLeituraUsuario();
    } else {
      _mostrarGrid = true;
    }
    setState(() {});
  }

  Future<void> _verificarLeituraUsuario() async {
    String? nomeUsuario = ModalRoute.of(context)!.settings.arguments as String?;
    if (nomeUsuario == null) return;

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(nomeUsuario)
          .get();

      _leituraConfirmada =
          snapshot.exists ? snapshot.get('leitura') ?? false : false;

      if (!snapshot.exists) {
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(nomeUsuario)
            .set({'leitura': false});
      }

      _mostrarGrid = _leituraConfirmada;
    } catch (e) {
      print('Erro ao verificar leitura: $e');
    }
  }

  Future<void> _confirmarLeitura(String nomeUsuario) async {
    try {
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(nomeUsuario)
          .update({'leitura': true});

      _mostrarGrid = true;
      _leituraConfirmada = true;
      setState(() {});
    } catch (e) {
      print('Erro ao confirmar leitura: $e');
    }
  }

  AppBar _construirAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: kPrimaryColor,
      toolbarHeight: 100,
      title: Column(
        children: [
          Text(widget.appBarTitle,
              style: GoogleFonts.lato(color: Colors.white)),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _construirCampoBusca(),
          ),
        ],
      ),
    );
  }

  TextField _construirCampoBusca() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchTerm = value;
        });
      },
      style: GoogleFonts.lato(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar...',
        hintStyle: GoogleFonts.lato(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // or 3, adjust as needed
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisualizarPdf(
              appBarTitle: document['title'],
              base64Pdf: document['base64'],
              voltar: true,
              naoMostrar: false,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: Center(
                child: Text(
                  document['title'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ),
          ),
          if (isAdmin)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  _showDeleteConfirmationDialog(document);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirCorpo(String? nomeUsuario) {
    final pdfsFiltrados = _documents.where((pdf) {
      return pdf['title']!.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return _mostrarGrid
        ? _buildGridView()
        : widget.appBarTitle == 'Ervas' &&
                !_leituraConfirmada &&
                nomeUsuario != null &&
                !isAdmin
            ? _construirTelaConfirmacaoLeitura(nomeUsuario)
            : _buildGridView();
  }

  Widget _construirTelaConfirmacaoLeitura(String nomeUsuario) {
    return Center(
      child: Column(
        children: [
          const Expanded(
            child: VisualizarPdf(
              appBarTitle: "Como consultar a Apostila?",
              pdfAssetPath: 'images/pdfs/0. COMO CONSULTAR A APOSTILA.pdf',
              voltar: false,
              naoMostrar: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _confirmarLeitura(nomeUsuario),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    side: const BorderSide(color: kPrimaryColor),
                  ),
                ),
                child: Text(
                  'Confirmar Leitura',
                  style: GoogleFonts.lato(fontSize: 13, color: kPrimaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? nomeUsuario = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: _construirAppBar(),
      body: Stack(
        children: [
          _construirCorpo(nomeUsuario),
          if (isAdmin) _construirBotaoUpload(),
          if (_isLoading)
            Container(
              color: kPrimaryColor,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Positioned _construirBotaoUpload() {
    return Positioned(
      bottom: 60.0,
      right: 16.0,
      child: FloatingActionButton(
        onPressed: () async {
          await _uploadDocument();
        },
        // Ação de upload aqui
        backgroundColor: kPrimaryColor,
        shape: const CircleBorder(side: BorderSide(color: Colors.white)),
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }

  String compressBase64(String base64Str) {
    List<int> bytes = utf8.encode(base64Str); // Converte para bytes
    List<int> compressed = GZipEncoder().encode(bytes) ?? [];
    return base64.encode(compressed); // Retorna Base64 compactado
  }

  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc'],
    );

    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      try {
        List<int> fileBytes = await file.readAsBytes();
        String base64String = base64.encode(fileBytes);
        String base64StringCmp = compressBase64(base64String);


        String? documentName = await _getDocumentNameFromUser();
        if (documentName == null || documentName.isEmpty) {
          return;
        }

        print('Document Name: ${fileName.split('.').first}');
        print('Base64 Length: ${base64String.length}');
        print('File Name: $fileName');
        print('File Type: ${fileName.split('.').last.toLowerCase()}');
        setState(() => _isLoading = true);
        await FirebaseFirestore.instance
            .collection("Documentos")
            .doc(widget.appBarTitle)
            .collection("Arquivos")
            .doc(documentName)
            .set({
          'nome': documentName,
          'base64': base64StringCmp,
          'nome_arquivo': fileName,
          'tipo_arquivo': fileName.split('.').last.toLowerCase(),
        });

        await _loadDocuments();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento carregado com sucesso!')),
        );
      } catch (e) {
        print('Error uploading document: $e');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar o documento')),
        );
      }
    }
  }

  String sanitizeDocumentName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s/-]'), '_').trim();
  }

  Future<String?> _getDocumentNameFromUser() async {
    TextEditingController nameController = TextEditingController();
    String? enteredName;

    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Nome do Documento"),
            content: CustomTextField(
              icon: Icons.paste,
              label: "Digite o nome do documento",
              controller: nameController,
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Cancelar"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text("Salvar"),
                onPressed: () {
                  enteredName = nameController.text;
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });

    return enteredName;
  }

  Future<void> _deleteDocument(Map<String, dynamic> document) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance
          .collection("Documentos")
          .doc(widget.appBarTitle)
          .collection("Arquivos")
          .doc(document['title'])
          .delete();
      await _loadDocuments();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento excluído com sucesso!')),
      );
    } catch (e) {
      print('Error deleting document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir o documento.')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      Map<String, dynamic> document) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem certeza que deseja excluir "${document['title']}"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () {
                _deleteDocument(document);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
