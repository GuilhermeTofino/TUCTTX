import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert'; // Importe o pacote dart:convert

import 'widgets/colors.dart';

class VisualizarPdf extends StatefulWidget {
  final String appBarTitle; // Título da AppBar
  final String? pdfAssetPath; // Caminho do PDF nos assets (agora anulável)
  final String? base64Pdf; // String base64 do PDF (compactado ou não)
  final bool voltar; // Mostrar botão de voltar?
  final bool naoMostrar; // Mostrar botão de download?

  const VisualizarPdf({
    super.key,
    required this.appBarTitle,
    this.pdfAssetPath, // Pode ser nulo
    this.base64Pdf, // Pode ser nulo
    required this.voltar,
    required this.naoMostrar,
  });

  @override
  State<VisualizarPdf> createState() => _VisualizarPdfState();
}

class _VisualizarPdfState extends State<VisualizarPdf> {
  String? pdfPath; // Caminho local do PDF
  late PdfControllerPinch _pdfControllerPinch; // Controlador do PDF

  @override
  void initState() {
    super.initState();
    _loadPdf(); // Carrega o PDF
  }

  /// 🔥 Função para descompactar Base64 se necessário
  String decompressBase64(String compressedBase64) {
    List<int> compressed = base64.decode(compressedBase64);
    List<int> decompressed = GZipDecoder().decodeBytes(compressed);
    return utf8.decode(decompressed); // Retorna Base64 original
  }

  /// 🔥 Carrega o PDF de diferentes fontes: Asset, Base64 (compactado ou não)
  Future<void> _loadPdf() async {
    try {
      if (widget.base64Pdf != null) {
        String base64Decoded;

        try {
          // 🔥 Primeiro, tenta descompactar. Se falhar, assume que já está em Base64 puro.
          base64Decoded = decompressBase64(widget.base64Pdf!);
        } catch (_) {
          base64Decoded = widget.base64Pdf!;
        }

        final bytes = base64Decode(base64Decoded);
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/temp.pdf'); // Arquivo temporário
        await file.writeAsBytes(bytes);
        _setPdfPath(file.path);
      } else if (widget.pdfAssetPath != null) {
        // ✅ Carrega dos assets
        final bytes = await rootBundle.load(widget.pdfAssetPath!);
        final dir = await getApplicationDocumentsDirectory();
        final file =
            File('${dir.path}/${widget.pdfAssetPath!.split('/').last}');
        await file.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        _setPdfPath(file.path);
      } else {
        // ❌ Nenhum PDF fornecido
        print("Erro: Nenhum PDF fornecido.");
      }
    } catch (e) {
      print('Erro ao carregar PDF: $e');
    }
  }

  /// Define o caminho do PDF e inicializa o controlador
  void _setPdfPath(String path) {
    setState(() {
      pdfPath = path;
      _pdfControllerPinch = PdfControllerPinch(
        document: PdfDocument.openFile(pdfPath!),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: widget.voltar,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.appBarTitle,
          style: GoogleFonts.lato(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                pdfPath != null
                    ? Expanded(
                        child: PdfViewPinch(
                          controller: _pdfControllerPinch,
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ],
            ),
            if (!widget.naoMostrar) _buildDownloadButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfControllerPinch.dispose();
    super.dispose();
  }

  /// 🔥 Compartilha o PDF
  void _sharePdfFile() {
    if (pdfPath != null) {
      Share.shareXFiles([XFile(pdfPath!)]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF ainda carregando...')),
      );
    }
  }

  /// 🔥 Constrói o botão de download
  Widget _buildDownloadButton() {
    return Positioned(
      bottom: 30.0,
      right: 16.0,
      child: FloatingActionButton.extended(
        onPressed: _sharePdfFile,
        heroTag: '${widget.appBarTitle}-share',
        backgroundColor: Colors.white,
        icon: const Icon(Icons.download, color: kPrimaryColor),
        label: Text("Baixar PDF",
            style: GoogleFonts.lato(fontSize: 13, color: kPrimaryColor)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
          side: const BorderSide(color: kPrimaryColor),
        ),
      ),
    );
  }
}
