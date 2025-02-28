class Usuario {
  final String id;
  final String nome;
  final String dataNascimento;
  final int idade;
  final String numeroEmergencia;
  final bool tirouSanto;
  final String orixaFrente;
  final String orixaJunto;
  final List<String> alergias;
  final String loginUsuario;
  final String funcao;
  final List<dynamic> mensalidade;
  final bool leitura;

  Usuario({
    required this.id,
    required this.nome,
    required this.dataNascimento,
    required this.idade,
    required this.numeroEmergencia,
    required this.tirouSanto,
    required this.orixaFrente,
    required this.orixaJunto,
    required this.alergias,
    required this.loginUsuario,
    required this.funcao,
    required this.mensalidade,
    required this.leitura,
  });

  factory Usuario.fromFirestore(Map<String, dynamic> data, String id) {
    return Usuario(
      id: id,
      nome: data["nome"] ?? "",
      dataNascimento: data["data_nascimento"] ?? "",
      idade: int.tryParse(data["idade"] ?? "0") ?? 0,
      numeroEmergencia: data["numero_emergencia"] ?? "",
      tirouSanto: data["tirou_santo"] == "Sim",
      orixaFrente: data["orixa_de_frente"] ?? "Não Sabe",
      orixaJunto: data["Orixa_junto"] ?? "Não Sabe",
      alergias: List<String>.from(data["alergias"] ?? []),
      loginUsuario: data["login_key"] ?? "",
      funcao: data["funcao"] ?? "",
      mensalidade: List<dynamic>.from(data["mensalidade"] ?? []),
      leitura: data["leitura"] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "nome": nome,
      "data_nascimento": dataNascimento,
      "idade": idade.toString(),
      "numero_emergencia": numeroEmergencia,
      "tirou_santo": tirouSanto ? "Sim" : "Não",
      "orixa_de_frente": orixaFrente,
      "Orixa_junto": orixaJunto,
      "alergias": alergias,
      'login_key': loginUsuario,
      'funcao': funcao,
      'mensalidade': mensalidade,
      'leitura': leitura,
    };
  }
}
