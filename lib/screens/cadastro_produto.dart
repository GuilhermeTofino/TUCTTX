import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/bazar_bloc.dart';
import '../models/bazar_model.dart';

class CadastroProdutoScreen extends StatefulWidget {
  const CadastroProdutoScreen({super.key});

  @override
  _CadastroProdutoScreenState createState() => _CadastroProdutoScreenState();
}

class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
  final BazarBloc _bloc = BazarBloc();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _fornecedorController = TextEditingController();
  String _categoriaSelecionada = "Salgados";
  File? _imagemSelecionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Produto")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _selecionarImagem,
                child: _imagemSelecionada != null
                    ? Image.file(_imagemSelecionada!,
                        height: 100, width: 100, fit: BoxFit.cover)
                    : Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.add_a_photo, size: 40),
                      ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome do Produto"),
              ),
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                items: [
                  "Salgados",
                  "Refrigerantes",
                  "Roupas",
                  "Guias",
                  "Pulseiras",
                  "Canecas",
                  "Artesanato"
                ].map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSelecionada = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Categoria"),
              ),
              TextField(
                controller: _precoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Preço (R\$)"),
              ),
              TextField(
                controller: _quantidadeController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Quantidade Inicial"),
              ),
              TextField(
                controller: _fornecedorController,
                decoration: const InputDecoration(labelText: "Fornecedor"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarProduto,
                child: const Text("Salvar Produto"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagemSelecionada = File(pickedFile.path);
      });
    }
  }

  void _salvarProduto() {
    if (_nomeController.text.isEmpty ||
        _precoController.text.isEmpty ||
        _quantidadeController.text.isEmpty ||
        _fornecedorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }

    ProdutoBazar novoProduto = ProdutoBazar(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeController.text,
      categoria: _categoriaSelecionada,
      preco: double.parse(_precoController.text),
      quantidade: int.parse(_quantidadeController.text),
      fornecedor: _fornecedorController.text,
      imagemBase64: '',
    );

    _bloc.adicionarProduto(novoProduto, _imagemSelecionada);
    Navigator.pop(context);
  }
}
