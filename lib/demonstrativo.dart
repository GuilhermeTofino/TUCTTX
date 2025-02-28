import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DemonstrativosScreen extends StatefulWidget {
  const DemonstrativosScreen({super.key});

  @override
  State<DemonstrativosScreen> createState() => _DemonstrativosScreenState();
}

class _DemonstrativosScreenState extends State<DemonstrativosScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final pdf = pw.Document();

  // Lista de meses
  final List<String> meses = [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ];

  // Lista de anos (de 2025 a 2045)
  final List<String> anos =
      List.generate(21, (index) => (2025 + index).toString());

  String? mesSelecionado;
  String? anoSelecionado;

  /// Busca os dados do Firestore diretamente pelo ID do documento (mês + ano)
  Future<Map<String, dynamic>?> _buscarRelatorio(String mesAno) async {
    try {
      DocumentSnapshot snapshot =
          await firestore.collection("relatorios").doc(mesAno).get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Erro ao buscar relatório: $e");
    }
    return null;
  }

  /// Gera um PDF estilizado com as informações do relatório
  Future<void> _gerarPdf() async {
    if (mesSelecionado == null || anoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione o mês e o ano.")),
      );
      return;
    }

    String mesAnoPesquisa = "${mesSelecionado?.toLowerCase()} $anoSelecionado";
    String mesAnoPdf = "$mesSelecionado de $anoSelecionado";
    Map<String, dynamic>? relatorio = await _buscarRelatorio(mesAnoPesquisa);

    if (relatorio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Nenhum relatório encontrado para este período.")),
      );
      return;
    }

    // Criar um novo documento PDF para evitar o erro
    final pdf = pw.Document();

    // Carregar a imagem do app
    final image = pw.MemoryImage(
      (await rootBundle.load('images/logo_TUCTTX.png')).buffer.asUint8List(),
    );

    // Dados do relatório
    double arrecadado = (relatorio["arrecadado"] ?? 0).toDouble();
    double totalDespesas = (relatorio["totalDespesas"] ?? 0).toDouble();
    double saldoFinal = (relatorio["saldoFinal"] ?? 0).toDouble();
    List<dynamic> despesas = relatorio["despesas"] ?? [];

    // Criar o PDF
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho com a logo e o nome do app
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(image, width: 50, height: 50),
                  pw.SizedBox(width: 10),
                  pw.Text("TUCTTX",
                      style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black)),
                ],
              ),

              pw.SizedBox(height: 20),

              // Título do demonstrativo
              pw.Text("Demonstrativo do Mês: $mesAnoPdf",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 10),

              // Seção de arrecadação
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                    "Total Arrecadado: R\$ ${arrecadado.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),

              pw.SizedBox(height: 15),

              // Seção de despesas fixas
              pw.Text("Despesas Fixas",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),

              for (var despesa in despesas) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(
                      "${despesa["nome"]}: R\$ ${despesa["valor"].toStringAsFixed(2)}",
                      style: const pw.TextStyle(fontSize: 14)),
                ),
              ],
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Total de despesas
              pw.Text(
                  "Total de Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 10),

              // Saldo final
              pw.Text("Saldo Mensal: R\$ ${saldoFinal.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green)),
            ],
          );
        },
      ),
    );

    // Exibir o PDF
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demonstrativos'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown de Mês
            DropdownButtonFormField<String>(
              value: mesSelecionado,
              decoration: const InputDecoration(
                labelText: 'Selecione o Mês',
                border: OutlineInputBorder(),
              ),
              items: meses.map((String mes) {
                return DropdownMenuItem<String>(
                  value: mes,
                  child: Text(mes),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  mesSelecionado = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // Dropdown de Ano
            DropdownButtonFormField<String>(
              value: anoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Selecione o Ano',
                border: OutlineInputBorder(),
              ),
              items: anos.map((String ano) {
                return DropdownMenuItem<String>(
                  value: ano,
                  child: Text(ano),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  anoSelecionado = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // Botão de Gerar PDF
            ElevatedButton(
              onPressed: _gerarPdf,
              child: const Text('Gerar Demonstrativo PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
