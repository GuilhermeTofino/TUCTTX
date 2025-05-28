import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String nomeArquivo;

  const PDFViewerScreen(
      {super.key, required this.url, required this.nomeArquivo});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  bool _isLoading = true;
  late PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    NetworkAssetBundle(Uri.parse(widget.url)).load(widget.url).then((bd) {
      final data = bd.buffer.asUint8List();
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(data),
      );
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: Text(widget.nomeArquivo),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (!_isLoading) PdfViewPinch(controller: _pdfController),
          if (_isLoading) const TucttxLoader(),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    final bd = await NetworkAssetBundle(Uri.parse(widget.url)).load(widget.url);
    final bytes = bd.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${widget.nomeArquivo}');
    await tempFile.writeAsBytes(bytes);

    Share.shareXFiles([XFile(tempFile.path)], text: widget.nomeArquivo);
  }
}
