class MenuOptionModel {
  final String id;
  final String title;
  final String icon; // Chave do ícone, ex: 'calendar_today_outlined'
  final String color; // Hex string ou 'primary'
  final String action; // Ex: 'route:/calendar', 'internal:health'
  final int order;
  final bool isEnabled;

  MenuOptionModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.action,
    required this.order,
    this.isEnabled = true,
  });

  factory MenuOptionModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuOptionModel(
      id: id,
      title: map['title'] ?? '',
      icon: map['icon'] ?? 'help_outline',
      color: map['color'] ?? 'primary',
      action: map['action'] ?? '',
      order: map['order'] ?? 999,
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'icon': icon,
      'color': color,
      'action': action,
      'order': order,
      'isEnabled': isEnabled,
    };
  }
}
