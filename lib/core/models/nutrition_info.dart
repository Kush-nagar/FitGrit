class NutritionInfo {
  final String foodName;
  final List<String> ingredients;
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final double fiber; // grams
  final double sugar; // grams
  final double sodium; // mg
  final String servingSize;
  final Map<String, dynamic>? additionalInfo; // for vitamins, minerals, etc.

  NutritionInfo({
    required this.foodName,
    required this.ingredients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.servingSize = '100g',
    this.additionalInfo,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      foodName: json['foodName'] ?? json['name'] ?? 'Unknown',
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? json['carbohydrates'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      servingSize: json['servingSize'] ?? '100g',
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'foodName': foodName,
      'ingredients': ingredients
          .where((i) => i.isNotEmpty)
          .toList(), // Filter out empty ingredients
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'servingSize': servingSize,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Only include additionalInfo if it's not null and not empty
    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      data['additionalInfo'] = additionalInfo;
    }

    return data;
  }

  // Calculate total macros percentage
  double get totalMacros => protein + carbs + fat;

  double get proteinPercentage =>
      totalMacros > 0 ? (protein / totalMacros) * 100 : 0;

  double get carbsPercentage =>
      totalMacros > 0 ? (carbs / totalMacros) * 100 : 0;

  double get fatPercentage => totalMacros > 0 ? (fat / totalMacros) * 100 : 0;
}
