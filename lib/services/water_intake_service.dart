import 'package:shared_preferences/shared_preferences.dart';

class WaterIntakeService {
  static const String _waterIntakeKey = 'water_intake';
  static const String _lastResetDateKey = 'water_last_reset_date';
  static const String _targetGlassesKey = 'target_water_glasses';

  /// Get current water intake (glasses) for today
  Future<int> getWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new day)
    await _checkAndResetIfNewDay(prefs);

    return prefs.getInt(_waterIntakeKey) ?? 0;
  }

  /// Add a glass of water
  Future<void> addWaterGlass() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new day)
    await _checkAndResetIfNewDay(prefs);

    final currentIntake = prefs.getInt(_waterIntakeKey) ?? 0;
    await prefs.setInt(_waterIntakeKey, currentIntake + 1);
  }

  /// Set water intake to a specific value (for manual adjustments)
  Future<void> setWaterIntake(int glasses) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new day)
    await _checkAndResetIfNewDay(prefs);

    await prefs.setInt(_waterIntakeKey, glasses);
  }

  /// Get target water glasses goal
  Future<int> getTargetGlasses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetGlassesKey) ?? 8; // Default 8 glasses
  }

  /// Set target water glasses goal
  Future<void> setTargetGlasses(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetGlassesKey, target);
  }

  /// Check if it's a new day and reset water intake if needed
  Future<void> _checkAndResetIfNewDay(SharedPreferences prefs) async {
    final lastResetString = prefs.getString(_lastResetDateKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    if (lastResetString != todayString) {
      // It's a new day, reset water intake
      await prefs.setInt(_waterIntakeKey, 0);
      await prefs.setString(_lastResetDateKey, todayString);
    }
  }

  /// Clear water intake (for testing or reset)
  Future<void> clearWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_waterIntakeKey);
  }

  /// Manual reset (for testing)
  Future<void> resetToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterIntakeKey, 0);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_lastResetDateKey, todayString);
  }
}
