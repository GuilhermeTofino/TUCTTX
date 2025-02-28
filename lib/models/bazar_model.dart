import 'dart:convert';
import 'dart:typed_data';

class ProdutoBazar {
  final String id;
  final String nome;
  final double valor;
  final String? imagemBase64;
  late final int quantidade;

  ProdutoBazar({
    required this.id,
    required this.nome,
    required this.valor,
    this.imagemBase64,
    required this.quantidade,
  });

  factory ProdutoBazar.fromFirestore(Map<String, dynamic> data, String id) {
    return ProdutoBazar(
      id: id,
      nome: data["nome"] ?? "Sem nome",
      valor: (data["valor"] ?? 0.0).toDouble(),
      imagemBase64: data["imagem_base64"],
      quantidade: data["quantidade"] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "nome": nome,
      "valor": valor,
      "imagem_base64": imagemBase64,
      "quantidade": quantidade,
    };
  }

  Uint8List? getImageBytes() {
    if (imagemBase64 == null) return null;
    return base64Decode(imagemBase64!);
  }
}
