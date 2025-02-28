import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bazar_model.dart';

class BazarData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retorna os produtos do estoque
  Stream<List<ProdutoBazar>> getEstoque() {
    return _firestore.collection("bazar_estoque").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProdutoBazar.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  // Retorna os produtos vendidos
  Stream<List<ProdutoBazar>> getVendidos() {
    return _firestore.collection("bazar_vendidos").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProdutoBazar.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  // Adiciona um novo produto ao estoque
  Future<void> adicionarProduto(ProdutoBazar produto) async {
    await _firestore.collection("bazar_estoque").add(produto.toFirestore());
  }
//Remover Produto 
  Future<void> removerProduto(String produtoId) async {
  await _firestore.collection("bazar_estoque").doc(produtoId).delete();
}

  // Marca um produto como vendido
  Future<void> venderProduto(ProdutoBazar produto) async {
    await _firestore.collection("bazar_estoque").doc(produto.id).delete();
    await _firestore.collection("bazar_vendidos").doc(produto.id).set(produto.toFirestore());

    // Atualiza financeiro
    DocumentSnapshot financeiroSnapshot =
        await _firestore.collection("financeiro").doc("dados").get();
    double totalArrecadado = financeiroSnapshot.exists
        ? (financeiroSnapshot["totalArrecadado"] ?? 0.0)
        : 0.0;

    await _firestore.collection("financeiro").doc("dados").update({
      "totalArrecadado": totalArrecadado + produto.valor,
    });

    // Cria log da venda
    String dataHoje = DateTime.now().toIso8601String().substring(0, 10);
    await _firestore.collection("bazar_vendas").doc(dataHoje).set({
      "produtos": FieldValue.arrayUnion([
        {"nome": produto.nome, "valor": produto.valor}
      ])
    });
  }
}