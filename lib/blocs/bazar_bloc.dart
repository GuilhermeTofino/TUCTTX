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

  Future<void> adicionarProduto(ProdutoBazar produto) async {
    await _bazarData.adicionarProduto(produto);
    carregarEstoque(); // Atualiza os produtos ao adicionar
  }

  Future<void> venderProduto(ProdutoBazar produto) async {
    await _bazarData.venderProduto(produto);
    carregarEstoque(); // Atualiza os produtos ao vender
  }

  Future<void> removerProduto(String produtoId) async {
    await _bazarData.removerProduto(produtoId);
  }

  void dispose() {
    _estoqueController.close();
  }
}
