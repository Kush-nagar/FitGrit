import 'package:shared_preferences/shared_preferences.dart';
import './presidential_fitness_benchmarks.dart';

/// Service for storing and retrieving user profile data
/// Stores age and gender for presidential fitness test benchmarks
class UserPreferencesService {
  static const String _keyAge = 'user_age';
  static const String _keyGender = 'user_gender';
  static const String _keyName = 'user_name';

  /// Save user age
  Future<bool> saveAge(int age) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_keyAge, age);
    } catch (e) {
      print('Error saving age: $e');
      return false;
    }
  }

  /// Get user age
  Future<int?> getAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyAge);
    } catch (e) {
      print('Error getting age: $e');
      return null;
    }
  }

  /// Save user gender
  Future<bool> saveGender(Gender gender) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
          _keyGender, gender == Gender.male ? 'male' : 'female');
    } catch (e) {
      print('Error saving gender: $e');
      return false;
    }
  }

  /// Get user gender
  Future<Gender?> getGender() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final genderStr = prefs.getString(_keyGender);
      if (genderStr == null) return null;
      return genderStr == 'male' ? Gender.male : Gender.female;
    } catch (e) {
      print('Error getting gender: $e');
      return null;
    }
  }

  /// Save user name
  Future<bool> saveName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyName, name);
    } catch (e) {
      print('Error saving name: $e');
      return false;
    }
  }

  /// Get user name
  Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyName);
    } catch (e) {
      print('Error getting name: $e');
      return null;
    }
  }

  /// Check if user has completed profile setup
  Future<bool> hasCompletedProfile() async {
    final age = await getAge();
    final gender = await getGender();
    return age != null && gender != null;
  }

  /// Clear all user preferences
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAge);
      await prefs.remove(_keyGender);
      await prefs.remove(_keyName);
      return true;
    } catch (e) {
      print('Error clearing preferences: $e');
      return false;
    }
  }
}
