class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String tenantSlug;
  final DateTime? createdAt;
  final String? photoUrl;

  // Campos de Fundamento
  final bool jaTirouSanto;
  final bool jogoComTata;
  final String? orixaFrente;
  final String? orixaJunto;

  // Novos Campos de Saúde e Cuidado
  final String? alergias;
  final String? medicamentos;
  final String? condicoesMedicas;
  final String? tipoSanguineo;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emergencyContact,
    required this.tenantSlug,
    this.createdAt,
    this.photoUrl,
    required this.jaTirouSanto,
    this.jogoComTata = false,
    this.orixaFrente,
    this.orixaJunto,
    this.alergias,
    this.medicamentos,
    this.condicoesMedicas,
    this.tipoSanguineo,
  });

  // --- O MÉTODO QUE FALTAVA ---
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? emergencyContact,
    String? tenantSlug,
    DateTime? createdAt,
    String? photoUrl,
    bool? jaTirouSanto,
    bool? jogoComTata,
    String? orixaFrente,
    String? orixaJunto,
    String? alergias,
    String? medicamentos,
    String? condicoesMedicas,
    String? tipoSanguineo,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      tenantSlug: tenantSlug ?? this.tenantSlug,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      jaTirouSanto: jaTirouSanto ?? this.jaTirouSanto,
      jogoComTata: jogoComTata ?? this.jogoComTata,
      orixaFrente: orixaFrente ?? this.orixaFrente,
      orixaJunto: orixaJunto ?? this.orixaJunto,
      alergias: alergias ?? this.alergias,
      medicamentos: medicamentos ?? this.medicamentos,
      condicoesMedicas: condicoesMedicas ?? this.condicoesMedicas,
      tipoSanguineo: tipoSanguineo ?? this.tipoSanguineo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'tenantSlug': tenantSlug,
      'createdAt': createdAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'jaTirouSanto': jaTirouSanto,
      'jogoComTata': jogoComTata,
      'orixaFrente': orixaFrente,
      'orixaJunto': orixaJunto,
      'alergias': alergias,
      'medicamentos': medicamentos,
      'condicoesMedicas': condicoesMedicas,
      'tipoSanguineo': tipoSanguineo,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      tenantSlug: map['tenantSlug'] ?? '',
      jaTirouSanto: map['jaTirouSanto'] ?? false,
      jogoComTata: map['jogoComTata'] ?? false,
      orixaFrente: map['orixaFrente'],
      orixaJunto: map['orixaJunto'],
      alergias: map['alergias'],
      medicamentos: map['medicamentos'],
      condicoesMedicas: map['condicoesMedicas'],
      tipoSanguineo: map['tipoSanguineo'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      photoUrl: map['photoUrl'],
    );
  }
}