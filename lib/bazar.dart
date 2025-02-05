import 'dart:convert';
import 'dart:io';
import 'package:app_tenda/colors.dart';
import 'package:app_tenda/solicitar_item_bazar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Bazar extends StatefulWidget {
  const Bazar({super.key});

  @override
  State<Bazar> createState() => _BazarState();
}

class _BazarState extends State<Bazar> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Busca os produtos do estoque
  Stream<QuerySnapshot> _getEstoque() {
    return firestore.collection("bazar_estoque").snapshots();
  }

  Stream<QuerySnapshot> _getVendidos() {
    return firestore.collection("bazar_vendidos").snapshots();
  }

  /// Marca um item como vendido
 Future<void> _venderProduto(DocumentSnapshot produto) async {
  bool confirmarVenda = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirmar Venda"),
      content: Text("Tem certeza que deseja marcar '${produto["nome"]}' como vendido?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Cancela a venda
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // Confirma a venda
          child: const Text("Confirmar"),
        ),
      ],
    ),
  );

  if (!confirmarVenda) return; // Se o usuário cancelar, sai da função

  String nome = produto["nome"];
  double valor = produto["valor"];

  // Remover do estoque
  await firestore.collection("bazar_estoque").doc(produto.id).delete();

  // Adicionar aos vendidos
  await firestore.collection("bazar_vendidos").doc(produto.id).set({
    "nome": nome,
    "valor": valor,
    "data": DateTime.now(),
  });

  // Atualizar total arrecadado no financeiro
  DocumentSnapshot financeiroSnapshot =
      await firestore.collection("financeiro").doc("dados").get();
  double totalArrecadado = financeiroSnapshot.exists
      ? (financeiroSnapshot["totalArrecadado"] ?? 0.0)
      : 0.0;

  await firestore.collection("financeiro").doc("dados").update({
    "totalArrecadado": totalArrecadado + valor,
  });

  // Criar log da venda no Firebase
  String dataHoje = DateTime.now().toIso8601String().substring(0, 10); // "YYYY-MM-DD"
  await firestore.collection("bazar_vendas").doc(dataHoje).set({
    "produtos": FieldValue.arrayUnion([
      {"nome": nome, "valor": valor}
    ])
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Produto '$nome' vendido por R\$ $valor")),
  );
}

  Future<void> _adicionarProduto() async {
  TextEditingController nomeController = TextEditingController();
  TextEditingController valorController = TextEditingController();
  XFile? imagemSelecionada;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text("Adicionar Produto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? imagem =
                      await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (imagem != null) {
                    setState(() {
                      imagemSelecionada = imagem;
                    });
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: imagemSelecionada != null
                      ? Image.file(File(imagemSelecionada!.path), fit: BoxFit.cover)
                      : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome do Produto"),
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

                if (nome.isEmpty || valor == null || valor <= 0 || imagemSelecionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Preencha todos os campos corretamente.")),
                  );
                  return;
                }

                // Exibir o diálogo de carregamento
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Salvando produto..."),
                      ],
                    ),
                  ),
                );

                try {
                  // Convertendo imagem para Base64
                  File file = File(imagemSelecionada!.path);
                  List<int> imageBytes = await file.readAsBytes();
                  String imagemBase64 = base64Encode(imageBytes);

                  // Adicionar ao Firestore
                  await FirebaseFirestore.instance.collection("bazar_estoque").add({
                    "nome": nome,
                    "valor": valor,
                    "imagem_base64": imagemBase64, // Salvando como Base64
                  });

                  // Fechar o diálogo de carregamento
                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Produto '$nome' adicionado ao estoque!")),
                  );
                } catch (e) {
                  Navigator.pop(context); // Fecha o loading caso haja erro
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erro ao adicionar produto ao estoque.")),
                  );
                }
              },
              child: const Text("Adicionar"),
            ),
          ],
        );
      },
    ),
  );
}

  /// Faz upload da imagem para o Firebase Storage e retorna a URL
  Future<String> _uploadImagem(XFile imagem) async {
    try {
      File file = File(imagem.path);
      String nomeArquivo = "bazar/${DateTime.now().millisecondsSinceEpoch}.jpg";

      // Criar referência no Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child(nomeArquivo);

      // Fazer upload do arquivo
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});

      // Retornar URL do arquivo salvo
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Erro no upload da imagem: $e");
      throw Exception("Erro ao enviar imagem para o servidor.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Bazar"),
  automaticallyImplyLeading: false,
  actions: [
    IconButton(
      icon: const Icon(Icons.add_shopping_cart),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SolicitarProdutoScreen()),
        );
      },
    ),
  ],
),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Estoque"),
                Tab(text: "Vendidos"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Aba de Estoque
                  StreamBuilder<QuerySnapshot>(
                    stream: _getEstoque(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var produtos = snapshot.data!.docs;

                      if (produtos.isEmpty) {
                        return const Center(
                            child: Text("Nenhum produto no estoque"));
                      }

                      return ListView.builder(
                        itemCount: produtos.length,
                        itemBuilder: (context, index) {
                          var produto = produtos[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: produto["imagem_base64"] != null
                                  ? Image.memory(
                                      base64Decode(produto["imagem_base64"]),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported,
                                      size: 50),
                              title: Text(produto["nome"]),
                              subtitle: Text(
                                  "R\$ ${produto["valor"].toStringAsFixed(2)}"),
                              trailing: ElevatedButton(
                                onPressed: () => _venderProduto(produto),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Vendido",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Aba de Vendidos
                  StreamBuilder<QuerySnapshot>(
                    stream: _getVendidos(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var produtos = snapshot.data!.docs;

                      if (produtos.isEmpty) {
                        return const Center(
                            child: Text("Nenhum produto vendido"));
                      }

                      return ListView.builder(
                        itemCount: produtos.length,
                        itemBuilder: (context, index) {
                          var produto = produtos[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: const Icon(Icons.check_circle,
                                  color: Colors.green, size: 40),
                              title: Text(produto["nome"]),
                              subtitle: Text(
                                  "Vendido por R\$ ${produto["valor"].toStringAsFixed(2)}"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarProduto,
        backgroundColor: Colors.white, // Fundo branco
        shape: const CircleBorder(
          side: BorderSide(
              color: kPrimaryColor, width: 2), // Borda na kPrimaryColor
        ),
        child:
            const Icon(Icons.add, color: kPrimaryColor), // "+" na kPrimaryColor
      ),
    );
  }
}
