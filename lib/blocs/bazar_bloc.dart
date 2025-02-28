import 'dart:io';
import 'package:rxdart/rxdart.dart';
import '../models/bazar_model.dart';
import '../data/bazar_data.dart';

class BazarBloc {
  final BazarData _bazarData = BazarData();
  final _estoqueController = BehaviorSubject<List<ProdutoBazar>>();

  Stream<List<ProdutoBazar>> get estoqueStream => _estoqueController.stream;

  BazarBloc() {
    carregarEstoque();
  }

  void carregarEstoque() {
    _bazarData.getEstoque().listen((produtos) {
      _estoqueController.add(produtos);
    }, onError: (error) {
      _estoqueController.addError(error);
    });
  }

  Future<void> adicionarProduto(ProdutoBazar produto, File? imagem) async {
    await _bazarData.adicionarProduto(produto, imagem: imagem);
    carregarEstoque();
  }

  Future<void> venderProduto(ProdutoBazar produto, int quantidadeVendida) async {
    await _bazarData.venderProduto(produto, quantidadeVendida);
    carregarEstoque();
  }

  void dispose() {
    _estoqueController.close();
  }
}