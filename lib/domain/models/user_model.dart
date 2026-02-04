class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String tenantSlug;
  final DateTime? createdAt;
  final String? photoUrl;
  final String role;

  // NOVO CAMPO: Lista de tokens para notificações
  final List<String>? fcmTokens;

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
  // Campos de Amaci
  final DateTime? lastAmaciDate;
  final DateTime? nextAmaciDate;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emergencyContact,
    required this.tenantSlug,
    this.createdAt,
    this.photoUrl,
    this.role = 'user',
    this.fcmTokens,
    required this.jaTirouSanto,
    this.jogoComTata = false,
    this.orixaFrente,
    this.orixaJunto,
    this.alergias,
    this.medicamentos,
    this.condicoesMedicas,
    this.tipoSanguineo,
    this.lastAmaciDate,
    this.nextAmaciDate,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? emergencyContact,
    String? tenantSlug,
    DateTime? createdAt,
    String? photoUrl,
    String? role,
    List<String>? fcmTokens,
    bool? jaTirouSanto,
    bool? jogoComTata,
    String? orixaFrente,
    String? orixaJunto,
    String? alergias,
    String? medicamentos,
    String? condicoesMedicas,
    String? tipoSanguineo,
    DateTime? lastAmaciDate,
    DateTime? nextAmaciDate,
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
      role: role ?? this.role,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      jaTirouSanto: jaTirouSanto ?? this.jaTirouSanto,
      jogoComTata: jogoComTata ?? this.jogoComTata,
      orixaFrente: orixaFrente ?? this.orixaFrente,
      orixaJunto: orixaJunto ?? this.orixaJunto,
      alergias: alergias ?? this.alergias,
      medicamentos: medicamentos ?? this.medicamentos,
      condicoesMedicas: condicoesMedicas ?? this.condicoesMedicas,
      tipoSanguineo: tipoSanguineo ?? this.tipoSanguineo,
      lastAmaciDate: lastAmaciDate ?? this.lastAmaciDate,
      nextAmaciDate: nextAmaciDate ?? this.nextAmaciDate,
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
      'role': role,
      'fcmTokens': fcmTokens,
      'jaTirouSanto': jaTirouSanto,
      'jogoComTata': jogoComTata,
      'orixaFrente': orixaFrente,
      'orixaJunto': orixaJunto,
      'alergias': alergias,
      'medicamentos': medicamentos,
      'condicoesMedicas': condicoesMedicas,
      'tipoSanguineo': tipoSanguineo,
      'lastAmaciDate': lastAmaciDate?.toIso8601String(),
      'nextAmaciDate': nextAmaciDate?.toIso8601String(),
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
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
      fcmTokens: map['fcmTokens'] != null
          ? List<String>.from(map['fcmTokens'])
          : null,
      lastAmaciDate: map['lastAmaciDate'] != null
          ? DateTime.parse(map['lastAmaciDate'])
          : null,
      nextAmaciDate: map['nextAmaciDate'] != null
          ? DateTime.parse(map['nextAmaciDate'])
          : null,
    );
  }
}
