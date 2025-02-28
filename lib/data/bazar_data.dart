import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bazar_model.dart';

class BazarData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ProdutoBazar>> getEstoque() {
    return _firestore.collection("bazar_estoque").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProdutoBazar.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> adicionarProduto(ProdutoBazar produto, {File? imagem}) async {
    String imagemBase64 = '';

    if (imagem != null) {
      List<int> imageBytes = imagem.readAsBytesSync();
      imagemBase64 = base64Encode(imageBytes);
    }

    // Debug: Exibir os dados antes de enviar para Firestore
    Map<String, dynamic> produtoData = {
      "nome": produto.nome,
      "categoria": produto.categoria,
      "preco": produto.preco,
      "quantidade": produto.quantidade,
      "fornecedor": produto.fornecedor,
      "imagemBase64": imagemBase64,
    };

    print("Dados do produto a serem salvos: $produtoData");

    await _firestore
        .collection("bazar_estoque")
        .doc(produto.id)
        .set(produtoData);
  }

  Future<void> venderProduto(
      ProdutoBazar produto, int quantidadeVendida) async {
    DocumentReference produtoRef =
        _firestore.collection("bazar_estoque").doc(produto.id);
    DocumentSnapshot produtoSnapshot = await produtoRef.get();

    if (produtoSnapshot.exists) {
      int estoqueAtual = produtoSnapshot['quantidade'] ?? 0;

      if (estoqueAtual > quantidadeVendida) {
        await produtoRef
            .update({"quantidade": estoqueAtual - quantidadeVendida});
      } else {
        await produtoRef.delete();
      }
    }
  }
}
