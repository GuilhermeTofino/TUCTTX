import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SolicitarProdutoScreen extends StatefulWidget {
  const SolicitarProdutoScreen({super.key});

  @override
  State<SolicitarProdutoScreen> createState() => _SolicitarProdutoScreenState();
}

class _SolicitarProdutoScreenState extends State<SolicitarProdutoScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController produtoController = TextEditingController();

  /// Adiciona um novo produto à lista de solicitações
  Future<void> _adicionarSolicitacao() async {
    String nomeProduto = produtoController.text.trim();

    if (nomeProduto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite um nome para o produto.")),
      );
      return;
    }

    await firestore.collection("bazar_solicitacoes").add({
      "nome": nomeProduto,
      "data": DateTime.now(),
    });

    produtoController.clear();
  }

  /// Remove uma solicitação do Firebase
  Future<void> _removerSolicitacao(String docId) async {
    await firestore.collection("bazar_solicitacoes").doc(docId).delete();
  }

  /// Gera a mensagem e abre o WhatsApp
  /// Gera a mensagem e abre o WhatsApp em uma conversa específica
  Future<void> _enviarListaParaWhatsApp() async {
    QuerySnapshot snapshot =
        await firestore.collection("bazar_solicitacoes").get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum produto na lista para enviar.")),
      );
      return;
    }

    // 🔥 Usamos links de imagens em vez de emojis
    String titulo = "*Lista de Produtos Solicitados para o Bazar:*\n\n";
    String marcador = "👉"; // Alternativa para 🔹 que pode funcionar
    String celular = "📲"; // Alternativa para 📲

    // Construção da mensagem
    String mensagem = titulo;
    for (var doc in snapshot.docs) {
      mensagem += "• ${doc["nome"]}\n";
    }

    mensagem += "\n*Enviado via App Tenda*";

    // ✅ Substituir número pelo correto (código do país + número sem espaços)
    String numeroWhatsApp = "551183407118";

    // ✅ Codificar a mensagem corretamente
    String url =
        "https://wa.me/$numeroWhatsApp?text=${Uri.encodeFull(mensagem)}";

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao abrir o WhatsApp.")),
        );
      }
    } catch (e) {
      print("Erro ao abrir o WhatsApp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao abrir o WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitar Produto"),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _enviarListaParaWhatsApp, // Botão de envio
            tooltip: "Enviar Lista",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: produtoController,
              decoration: const InputDecoration(
                labelText: "Nome do Produto",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _adicionarSolicitacao,
              child: const Text("Adicionar Solicitação"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore.collection("bazar_solicitacoes").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var solicitacoes = snapshot.data!.docs;

                  if (solicitacoes.isEmpty) {
                    return const Center(
                        child: Text("Nenhum produto solicitado."));
                  }

                  return ListView.builder(
                    itemCount: solicitacoes.length,
                    itemBuilder: (context, index) {
                      var solicitacao = solicitacoes[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(solicitacao["nome"]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _removerSolicitacao(solicitacao.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
