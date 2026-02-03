class NutritionLog {
  final String? id;
  final String? userId;
  final DateTime loggedAt;
  final String foodName;
  final String? source;
  final double grams;
  final String? servingLabel;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  NutritionLog({
    this.id,
    this.userId,
    required this.loggedAt,
    required this.foodName,
    this.source,
    required this.grams,
    this.servingLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory NutritionLog.fromJson(Map<String, dynamic> json) {
    return NutritionLog(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      foodName: json['food_name'] as String,
      source: json['source'] as String?,
      grams: (json['grams'] as num?)?.toDouble() ?? (json['amount_grams'] as num?)?.toDouble() ?? 0.0,
      servingLabel: json['serving_label'] as String?,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'logged_at': loggedAt.toIso8601String(),
      'food_name': foodName,
      if (source != null) 'source': source,
      'grams': grams,
      if (servingLabel != null) 'serving_label': servingLabel,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  NutritionLog copyWith({
    String? id,
    String? userId,
    DateTime? loggedAt,
    String? foodName,
    String? source,
    double? grams,
    String? servingLabel,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
  }) {
    return NutritionLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loggedAt: loggedAt ?? this.loggedAt,
      foodName: foodName ?? this.foodName,
      source: source ?? this.source,
      grams: grams ?? this.grams,
      servingLabel: servingLabel ?? this.servingLabel,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }
}
