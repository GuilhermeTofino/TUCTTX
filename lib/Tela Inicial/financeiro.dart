import 'package:app_tenda/colors.dart';
import 'package:app_tenda/entrar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Financeiro extends StatefulWidget {
  const Financeiro({super.key});

  @override
  State<Financeiro> createState() => _FinanceiroState();
}

class _FinanceiroState extends State<Financeiro> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController arrecadadoController = TextEditingController();
  double totalArrecadado = 0.0;

  List<Map<String, dynamic>> despesas = [
    {"nome": "Aluguel", "valor": 1200.00},
    {"nome": "Água", "valor": 150.00},
    {"nome": "Luz", "valor": 250.00},
  ];

  double saldoAnterior = 0.0;

  double get totalDespesas =>
      despesas.fold(0, (sum, item) => sum + item["valor"]);
  double get percentualCoberto =>
      totalArrecadado == 0 ? 0 : (totalArrecadado / totalDespesas) * 100;
  double get saldoFinal => totalArrecadado - totalDespesas;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      DocumentSnapshot snapshot =
          await firestore.collection("financeiro").doc("dados").get();
      if (snapshot.exists) {
        setState(() {
          despesas = List<Map<String, dynamic>>.from(snapshot["despesas"]);
          saldoAnterior = snapshot["saldoAnterior"] ?? 0.0;
          totalArrecadado = snapshot["totalArrecadado"] ?? 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Valores atualizados com sucesso!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar valores.")),
      );
    }
  }

  void adicionarValor() {
    double novoValor = double.tryParse(arrecadadoController.text) ?? 0.0;
    if (novoValor > 0) {
      setState(() {
        totalArrecadado += novoValor;
      });
      firestore.collection("financeiro").doc("dados").update({
        "totalArrecadado": totalArrecadado,
      });
      arrecadadoController.clear();
    }
  }

  void adicionarDespesa() {
    TextEditingController nomeController = TextEditingController();
    TextEditingController valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar Nova Despesa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Nome da Despesa"),
            ),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Valor (R\$)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              String nome = nomeController.text.trim();
              double? valor = double.tryParse(valorController.text);

              if (nome.isNotEmpty && valor != null && valor > 0) {
                setState(() {
                  despesas.add({"nome": nome, "valor": valor});
                });

                // Atualiza o Firestore
                await firestore.collection("financeiro").doc("dados").update({
                  "despesas": despesas,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Despesa '$nome' adicionada com sucesso!")),
                );
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  Future<void> gerarRelatorio() async {
    if (!isAdmin) return;

    // Buscar o total arrecadado atualizado do Firestore antes de calcular
    DocumentSnapshot snapshot =
        await firestore.collection("financeiro").doc("dados").get();
    double totalArrecadadoFirebase =
        snapshot.exists ? snapshot["totalArrecadado"] ?? 0.0 : 0.0;

    String mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now());

    // Recalcular saldo final usando o valor atualizado do Firestore
    double saldoFinalCalculado = totalArrecadadoFirebase - totalDespesas;

    // Atualizar Firestore com o relatório do mês
    await firestore.collection("relatorios").doc(mesAno).set({
      "mes": mesAno,
      "despesas": despesas,
      "totalDespesas": totalDespesas,
      "arrecadado": totalArrecadadoFirebase,
      "saldoFinal": saldoFinalCalculado,
    });

    // Atualizar Firestore para o próximo mês, carregando saldo positivo ou negativo
    await firestore.collection("financeiro").doc("dados").set({
      "despesas": despesas,
      "saldoAnterior": saldoFinalCalculado,
      "totalArrecadado": 0.0, // Zerar o total arrecadado para o novo mês
    });

    // Atualizar estado do app para refletir os novos valores
    setState(() {
      saldoAnterior = saldoFinalCalculado;
      totalArrecadado = 0.0;
    });

    // Criar mensagem formatada para exibir no AlertDialog
    String relatorioDetalhado = """
📅 Relatório de $mesAno
----------------------------------
${despesas.map((d) => "📌 ${d['nome']}: R\$ ${d['valor'].toStringAsFixed(2)}").join("\n")}
----------------------------------
💰 Total de Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}
📈 Total Arrecadado: R\$ ${totalArrecadadoFirebase.toStringAsFixed(2)}
${saldoFinalCalculado >= 0 ? "✅ Saldo Positivo: R\$ ${saldoFinalCalculado.toStringAsFixed(2)}" : "❌ Saldo Negativo: R\$ ${saldoFinalCalculado.abs().toStringAsFixed(2)}"}
----------------------------------
✅ Relatório salvo com sucesso no Firebase!
""";

    // Exibir o relatório corretamente
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("📊 Relatório Mensal",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(relatorioDetalhado, style: const TextStyle(fontSize: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Financeiro"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: "Atualizar valores",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: arrecadadoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Adicionar valor ao Total Arrecadado",
                      prefixText: "R\$ ",
                    ),
                    enabled: isAdmin,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isAdmin ? adicionarValor : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(
                              color: isAdmin ? kPrimaryColor : Colors.grey))),
                  child: Text("+",
                      style: GoogleFonts.lato(
                          fontSize: 20,
                          color: isAdmin ? kPrimaryColor : Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: despesas.length,
                itemBuilder: (context, index) {
                  Widget listItem = ListTile(
                    title: Text(despesas[index]["nome"]),
                    subtitle: Text(
                        "R\$ ${despesas[index]["valor"].toStringAsFixed(2)}"),
                  );

                  return isAdmin
                      ? Dismissible(
                          key: Key(
                              despesas[index]["nome"]), // Identificação única
                          direction: DismissDirection
                              .endToStart, // Arrasta para excluir
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) async {
                            String nomeDespesa = despesas[index]["nome"];

                            setState(() {
                              despesas.removeAt(index);
                            });

                            // Atualizar Firestore após remoção
                            await firestore
                                .collection("financeiro")
                                .doc("dados")
                                .update({
                              "despesas": despesas,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "$nomeDespesa removido com sucesso!")),
                            );
                          },
                          child: listItem,
                        )
                      : listItem; // Se não for admin, apenas exibe o ListTile normal
                },
              ),
            ),
            Text("Total de Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Total Arrecadado: R\$ ${totalArrecadado.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            Text("Saldo Anterior: R\$ ${saldoAnterior.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16)),
            Text("Saldo Final: R\$ ${saldoFinal.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16,
                  color: saldoFinal >= 0 ? Colors.green : Colors.red,
                )),
            Text("Cobertura: ${percentualCoberto.toStringAsFixed(2)}%",
                style: TextStyle(
                  fontSize: 16,
                  color: percentualCoberto >= 100 ? Colors.green : Colors.red,
                )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: isAdmin ? adicionarDespesa : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(
                              color: isAdmin ? kPrimaryColor : Colors.grey)),
                    ),
                    child: Text("Nova Despesa",
                        style: GoogleFonts.lato(
                            fontSize: 13,
                            color: isAdmin ? kPrimaryColor : Colors.grey))),
                ElevatedButton(
                  onPressed: isAdmin ? gerarRelatorio : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(
                              color: isAdmin ? kPrimaryColor : Colors.grey))),
                  child: Text("Gerar Relatório Mês",
                      style: GoogleFonts.lato(
                          fontSize: 13,
                          color: isAdmin ? kPrimaryColor : Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
