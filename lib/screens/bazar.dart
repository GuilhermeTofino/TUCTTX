import 'dart:convert';
import 'package:flutter/material.dart';
import '../blocs/bazar_bloc.dart';
import '../models/bazar_model.dart';

class BazarScreen extends StatefulWidget {
  const BazarScreen({super.key});

  @override
  _BazarScreenState createState() => _BazarScreenState();
}

class _BazarScreenState extends State<BazarScreen> {
  final BazarBloc _bloc = BazarBloc();

  @override
  void initState() {
    super.initState();
    _bloc.carregarEstoque();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Bazar"), automaticallyImplyLeading: false),
      body: StreamBuilder<List<ProdutoBazar>>(
        stream: _bloc.estoqueStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.map((produto) {
              return ListTile(
                leading: produto.imagemBase64.isNotEmpty
                    ? Image.memory(base64Decode(produto.imagemBase64),
                        width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported, size: 50),
                title: Text(produto.nome),
                subtitle: Text(
                    "R\$ ${produto.preco.toStringAsFixed(2)} - ${produto.quantidade} disponíveis"),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.remove_shopping_cart, color: Colors.red),
                  onPressed: () => _bloc.venderProduto(produto, 1),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, "/cadastro_produto"),
        child: const Icon(Icons.add),
      ),
    );
  }
}
