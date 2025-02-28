import 'dart:convert';
import 'dart:io';

import 'package:app_tenda/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bazar_model.dart';
import '../blocs/bazar_bloc.dart';

class Bazar extends StatefulWidget {
  const Bazar({super.key});

  @override
  State<Bazar> createState() => _BazarState();
}

class _BazarState extends State<Bazar> {
  final BazarBloc _bloc = BazarBloc();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  @override
  void initState() {
    super.initState();
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
              // Mantém a navegação para solicitar produtos
              Navigator.pushNamed(
                context,
                '/solicitar_produto',
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
                  _buildListaProdutos(_bloc.estoqueStream, true),
                  _buildListaProdutos(_bloc.estoqueStream, false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogAdicionarProduto,
        backgroundColor: Colors.white, // Fundo branco
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Deixa o botão redondo
          side: const BorderSide(
              color: kPrimaryColor, width: 2), // Borda fina na cor primária
        ),
        child: const Icon(Icons.add,
            color: kPrimaryColor), // Ícone + na cor primária
      ),
    );
  }

  Widget _buildListaProdutos(
      Stream<List<ProdutoBazar>> stream, bool podeVender) {
    return StreamBuilder<List<ProdutoBazar>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var produtos = snapshot.data!;
        if (produtos.isEmpty)
          return const Center(child: Text("Nenhum produto encontrado"));

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 colunas
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio:
                0.8, // Proporção maior para os cards ficarem mais altos
          ),
          itemCount: produtos.length,
          itemBuilder: (context, index) {
            var produto = produtos[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ajustar a imagem para ocupar mais espaço do card
                  Container(
                    height:
                        120, // Definir uma altura fixa para aumentar a imagem
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                      color:
                          Colors.grey[300], // Fundo cinza claro para contraste
                    ),
                    child: produto.imagemBase64 != null
                        ? Image.memory(produto.getImageBytes()!,
                            fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.image_not_supported,
                                size: 60, color: Colors.grey),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(produto.nome,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("R\$ ${produto.valor.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.green)),
                        const SizedBox(height: 5),
                        if (podeVender) // Somente para estoque!
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                onPressed: () => _bloc.venderProduto(produto),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _confirmarRemocaoProduto(produto.id),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarRemocaoProduto(String produtoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remover Produto"),
          content: const Text(
              "Tem certeza de que deseja remover este produto do estoque?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _bloc.removerProduto(produtoId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(),
              child: const Text(
                "Remover",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogAdicionarProduto() {
  File? _imagemSelecionada;
  String? _erroImagem;
  TextEditingController quantidadeController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Adicionar Produto"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? imagem =
                        await picker.pickImage(source: ImageSource.gallery);

                    if (imagem != null) {
                      setState(() {
                        _imagemSelecionada = File(imagem.path);
                        _erroImagem = null; // Remove o erro ao selecionar uma imagem
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imagemSelecionada != null
                        ? Image.file(_imagemSelecionada!, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt,
                            color: Colors.grey, size: 50),
                  ),
                ),
                if (_erroImagem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      _erroImagem!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nomeController,
                  decoration:
                      const InputDecoration(labelText: "Nome do Produto"),
                ),
                TextField(
                  controller: _valorController,
                  decoration: const InputDecoration(labelText: "Valor (R\$)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantidadeController,
                  decoration: const InputDecoration(labelText: "Quantidade"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_imagemSelecionada == null) {
                    setState(() {
                      _erroImagem = "A imagem do produto é obrigatória!";
                    });
                    return;
                  }

                  _adicionarProduto(_imagemSelecionada, quantidadeController.text);
                  Navigator.pop(context);
                },
                child: const Text("Adicionar", style: TextStyle(color: Colors.green)),
              ),
            ],
          );
        },
      );
    },
  );
}

void _adicionarProduto(File? imagem, String quantidadeTexto) {
  String nome = _nomeController.text.trim();
  double? valor = double.tryParse(_valorController.text.trim());
  int? quantidade = int.tryParse(quantidadeTexto.trim());

  if (nome.isNotEmpty && valor != null && imagem != null && quantidade != null) {
    String imagemBase64 = base64Encode(imagem.readAsBytesSync());

    ProdutoBazar novoProduto = ProdutoBazar(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      valor: valor,
      imagemBase64: imagemBase64,
      quantidade: quantidade,
    );

    _bloc.adicionarProduto(novoProduto);
    _nomeController.clear();
    _valorController.clear();
  }
}

  @override
  void dispose() {
    _bloc.dispose();
    _nomeController.dispose();
    _valorController.dispose();
    super.dispose();
  }
}
