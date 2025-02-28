class ProdutoBazar {
  String id;
  String nome;
  String categoria;
  double preco;
  int quantidade;
  String fornecedor;
  String imagemBase64;

  ProdutoBazar({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.preco,
    required this.quantidade,
    required this.fornecedor,
    required this.imagemBase64,
  });

  factory ProdutoBazar.fromFirestore(Map<String, dynamic> data, String id) {
    return ProdutoBazar(
      id: id,
      nome: data['nome'],
      categoria: data['categoria'],
      preco: (data['preco'] as num).toDouble(),
      quantidade: data['quantidade'] ?? 0,
      fornecedor: data['fornecedor'],
      imagemBase64: data['imagemBase64'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'categoria': categoria,
      "preco": preco.isFinite ? preco : 0.0,
      'quantidade': quantidade,
      'fornecedor': fornecedor,
      'imagemBase64': imagemBase64,
    };
  }
}
