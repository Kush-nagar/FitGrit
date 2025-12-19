/// Model representing a recipe with complete nutritional information
class Recipe {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final NutritionFacts nutrition;
  final String? imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    this.imageUrl,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
  });

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Unknown Recipe',
      description: json['description']?.toString() ?? '',
      ingredients: _parseList(json['ingredients']),
      steps: _parseList(json['steps']),
      nutrition: NutritionFacts.fromJson(json['nutrition'] ?? {}),
      imageUrl: json['imageUrl']?.toString(),
      prepTimeMinutes: _parseInt(json['prepTimeMinutes'], 15),
      cookTimeMinutes: _parseInt(json['cookTimeMinutes'], 30),
      servings: _parseInt(json['servings'], 4),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'nutrition': nutrition.toJson(),
      'imageUrl': imageUrl,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
    };
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}

/// Nutrition facts for a recipe
class NutritionFacts {
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final double fiber; // grams
  final double sugar; // grams
  final double sodium; // mg

  NutritionFacts({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    return NutritionFacts(
      calories: _parseDouble(json['calories'], 0),
      protein: _parseDouble(json['protein'], 0),
      carbs: _parseDouble(json['carbs'], 0),
      fat: _parseDouble(json['fat'], 0),
      fiber: _parseDouble(json['fiber'], 0),
      sugar: _parseDouble(json['sugar'], 0),
      sodium: _parseDouble(json['sodium'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Total macros in grams
  double get totalMacros => protein + carbs + fat;
}
