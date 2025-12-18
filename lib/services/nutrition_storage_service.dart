import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/nutrition_info.dart';

class NutritionStorageService {
  static const String _loggedFoodsKey = 'logged_foods';
  static const String _dailyGoalKey = 'daily_nutrition_goal';
  static const String _lastResetDateKey = 'last_reset_date';

  /// Save a logged food entry
  Future<void> logFood(NutritionInfo nutritionInfo) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new day)
    await _checkAndResetIfNewDay(prefs);

    // Get existing logs
    final existingLogs = await getLoggedFoods();

    // Add new entry
    existingLogs.add(nutritionInfo.toJson());

    // Save back
    await prefs.setString(_loggedFoodsKey, jsonEncode(existingLogs));
  }

  /// Get all logged foods for today
  Future<List<Map<String, dynamic>>> getLoggedFoods() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new day)
    await _checkAndResetIfNewDay(prefs);

    final logsString = prefs.getString(_loggedFoodsKey);
    if (logsString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(logsString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get today's total nutrition
  Future<Map<String, double>> getTodaysTotals() async {
    final logs = await getLoggedFoods();

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;

    for (var log in logs) {
      totalCalories += (log['calories'] ?? 0).toDouble();
      totalProtein += (log['protein'] ?? 0).toDouble();
      totalCarbs += (log['carbs'] ?? 0).toDouble();
      totalFat += (log['fat'] ?? 0).toDouble();
      totalFiber += (log['fiber'] ?? 0).toDouble();
      totalSugar += (log['sugar'] ?? 0).toDouble();
      totalSodium += (log['sodium'] ?? 0).toDouble();
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
      'sugar': totalSugar,
      'sodium': totalSodium,
    };
  }

  /// Set daily nutrition goal
  Future<void> setDailyGoal({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final goal = {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
    await prefs.setString(_dailyGoalKey, jsonEncode(goal));
  }

  /// Get daily nutrition goal
  Future<Map<String, double>> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final goalString = prefs.getString(_dailyGoalKey);

    if (goalString == null) {
      // Default goal
      return {
        'calories': 2000,
        'protein': 150,
        'carbs': 200,
        'fat': 70,
      };
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(goalString);
      return {
        'calories': (decoded['calories'] ?? 2000).toDouble(),
        'protein': (decoded['protein'] ?? 150).toDouble(),
        'carbs': (decoded['carbs'] ?? 200).toDouble(),
        'fat': (decoded['fat'] ?? 70).toDouble(),
      };
    } catch (e) {
      return {
        'calories': 2000,
        'protein': 150,
        'carbs': 200,
        'fat': 70,
      };
    }
  }

  /// Calculate progress towards daily goal
  Future<Map<String, double>> getProgress() async {
    final totals = await getTodaysTotals();
    final goals = await getDailyGoal();

    return {
      'calories': goals['calories']! > 0
          ? (totals['calories']! / goals['calories']!)
          : 0,
      'protein':
          goals['protein']! > 0 ? (totals['protein']! / goals['protein']!) : 0,
      'carbs': goals['carbs']! > 0 ? (totals['carbs']! / goals['carbs']!) : 0,
      'fat': goals['fat']! > 0 ? (totals['fat']! / goals['fat']!) : 0,
    };
  }

  /// Delete a logged food entry by index
  Future<void> deleteLoggedFood(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getLoggedFoods();

    if (index >= 0 && index < logs.length) {
      logs.removeAt(index);
      await prefs.setString(_loggedFoodsKey, jsonEncode(logs));
    }
  }

  /// Clear all logged foods (for testing or reset)
  Future<void> clearAllLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedFoodsKey);
  }

  /// Check if it's a new day and reset logs if needed
  Future<void> _checkAndResetIfNewDay(SharedPreferences prefs) async {
    final lastResetString = prefs.getString(_lastResetDateKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    if (lastResetString != todayString) {
      // It's a new day, reset logs
      await prefs.remove(_loggedFoodsKey);
      await prefs.setString(_lastResetDateKey, todayString);
    }
  }

  /// Manual reset (for testing)
  Future<void> resetToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedFoodsKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_lastResetDateKey, todayString);
  }
}
