enum FinancialGoalType { monthly, annual }

enum FinancialGoalCategory { total, monthly_fee, bazaar }

class FinancialGoalModel {
  final String id;
  final String tenantId;
  final FinancialGoalType type;
  final int year;
  final int? month; // Null if annual
  final double targetValue;
  final FinancialGoalCategory category;
  final DateTime updatedAt;

  FinancialGoalModel({
    required this.id,
    required this.tenantId,
    required this.type,
    required this.year,
    this.month,
    required this.targetValue,
    this.category = FinancialGoalCategory.total,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'type': type.name,
      'year': year,
      'month': month,
      'targetValue': targetValue,
      'category': category.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinancialGoalModel.fromMap(Map<String, dynamic> map) {
    return FinancialGoalModel(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      type: FinancialGoalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FinancialGoalType.monthly,
      ),
      year: map['year']?.toInt() ?? DateTime.now().year,
      month: map['month']?.toInt(),
      targetValue: (map['targetValue'] ?? 0.0).toDouble(),
      category: FinancialGoalCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FinancialGoalCategory.total,
      ),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
