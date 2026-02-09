class EntityModel {
  final String type;
  final String name;

  const EntityModel({required this.type, required this.name});

  Map<String, dynamic> toMap() {
    return {'type': type, 'name': name};
  }

  factory EntityModel.fromMap(Map<String, dynamic> map) {
    return EntityModel(type: map['type'] ?? '', name: map['name'] ?? '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EntityModel && other.type == type && other.name == name;
  }

  @override
  int get hashCode => type.hashCode ^ name.hashCode;
}
