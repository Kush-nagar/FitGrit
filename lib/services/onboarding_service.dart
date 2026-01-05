import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_onboarding_model.dart';
import './gemini_service.dart';
import './user_preferences_service.dart';
import './water_intake_service.dart';
import './presidential_fitness_benchmarks.dart';

class OnboardingService {
  static const String _onboardingKey = 'user_onboarding_data';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _dailyCaloriesKey = 'daily_calorie_goal';

  final UserPreferencesService _userPrefsService = UserPreferencesService();
  final WaterIntakeService _waterIntakeService = WaterIntakeService();

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Save onboarding data
  Future<bool> saveOnboardingData(UserOnboardingModel data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      await prefs.setString(_onboardingKey, jsonString);
      await prefs.setBool(_onboardingCompleteKey, true);

      // Also save to user preferences service for Presidential fitness tests
      await _userPrefsService.saveName(data.name);
      await _userPrefsService.saveAge(data.age);
      await _userPrefsService.saveGender(
          data.gender.toLowerCase() == 'male' ? Gender.male : Gender.female);

      return true;
    } catch (e) {
      print('Error saving onboarding data: $e');
      return false;
    }
  }

  /// Get saved onboarding data
  Future<UserOnboardingModel?> getOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_onboardingKey);

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserOnboardingModel.fromJson(jsonMap);
    } catch (e) {
      print('Error getting onboarding data: $e');
      return null;
    }
  }

  /// Get personalized recommendations from Gemini
  Future<Map<String, int>> getPersonalizedRecommendations(
    UserOnboardingModel data,
    String geminiApiKey,
  ) async {
    try {
      final geminiService = GeminiService(apiKey: geminiApiKey);

      // Build a comprehensive prompt for Gemini
      final prompt = _buildRecommendationPrompt(data);

      // Call Gemini API
      final response = await geminiService.getTextRecommendations(prompt);

      // Parse response to extract water intake and calorie recommendations
      final recommendations = _parseRecommendations(response);

      return recommendations;
    } catch (e) {
      print('Error getting Gemini recommendations: $e');
      // Return default values based on basic calculations
      return _getDefaultRecommendations(data);
    }
  }

  /// Build prompt for Gemini API
  String _buildRecommendationPrompt(UserOnboardingModel data) {
    final activityLevelStr = _getActivityLevelString(data.activityLevel);
    final goalStr = _getGoalString(data.overallGoal);
    final dietStr = data.dietType != null
        ? _getDietTypeString(data.dietType!)
        : 'No specific diet';

    return '''
You are a professional nutritionist and fitness expert. Based on the following user profile, provide personalized daily recommendations for water intake and caloric intake.

USER PROFILE:
- Name: ${data.name}
- Age: ${data.age}
- Gender: ${data.gender}
- Height: ${data.heightCm} cm
- Weight: ${data.weightKg} kg
- Overall Goal: $goalStr
- Time Horizon: ${_getTimeHorizonString(data.timeHorizon)}
- Activity Level: $activityLevelStr
- Person Type: ${data.personType == PersonType.sportsPlayer ? 'Sports Player' : 'Regular Person'}
${data.sport != null ? '- Sport: ${data.sport}' : ''}
- Exercise Preferences: ${data.exercisePreferences.join(', ')}
- Equipment Available: ${data.equipment.join(', ')}
- Diet Type: $dietStr
${data.allergies.isNotEmpty ? '- Allergies: ${data.allergies.join(', ')}' : ''}
${data.dislikes.isNotEmpty ? '- Dislikes: ${data.dislikes.join(', ')}' : ''}

Calculate:
1. Daily water intake in glasses (1 glass = 250ml)
2. Daily caloric intake

Consider:
- BMR (Basal Metabolic Rate) based on age, gender, height, weight
- Activity level multiplier
- Goal adjustments (deficit for weight loss, surplus for muscle gain)
- Sports player needs higher intake
- Special dietary requirements

IMPORTANT: Respond ONLY with a JSON object in this exact format, no other text:
{
  "waterIntakeGlasses": <number>,
  "dailyCalories": <number>
}
''';
  }

  /// Parse Gemini response to extract recommendations
  Map<String, int> _parseRecommendations(String response) {
    try {
      // Clean response - remove markdown code blocks if present
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();

      final jsonMap = jsonDecode(cleanResponse) as Map<String, dynamic>;

      return {
        'waterIntakeGlasses': (jsonMap['waterIntakeGlasses'] as num).toInt(),
        'dailyCalories': (jsonMap['dailyCalories'] as num).toInt(),
      };
    } catch (e) {
      print('Error parsing recommendations: $e');
      throw Exception('Failed to parse Gemini recommendations');
    }
  }

  /// Get default recommendations based on basic calculations
  Map<String, int> _getDefaultRecommendations(UserOnboardingModel data) {
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (data.gender.toLowerCase() == 'male') {
      bmr = (10 * data.weightKg) + (6.25 * data.heightCm) - (5 * data.age) + 5;
    } else {
      bmr =
          (10 * data.weightKg) + (6.25 * data.heightCm) - (5 * data.age) - 161;
    }

    // Apply activity multiplier
    double activityMultiplier = _getActivityMultiplier(data.activityLevel);
    double tdee = bmr * activityMultiplier;

    // Adjust for sports player
    if (data.personType == PersonType.sportsPlayer) {
      tdee *= 1.15; // 15% increase for sports players
    }

    // Adjust for goal
    double calories = tdee;
    switch (data.overallGoal) {
      case OverallGoal.loseWeight:
        calories -= 500; // 500 calorie deficit
        break;
      case OverallGoal.gainMuscle:
        calories += 300; // 300 calorie surplus
        break;
      case OverallGoal.maintain:
      case OverallGoal.mentalWellbeing:
        // Keep TDEE as is
        break;
    }

    // If manual caloric target is set, use it
    if (data.caloricTargetPreference == CaloricTargetPreference.manual &&
        data.manualCaloricTarget != null) {
      calories = data.manualCaloricTarget!.toDouble();
    }

    // Calculate water intake (basic formula: 30-35ml per kg of body weight)
    double waterMl = data.weightKg * 33; // 33ml per kg

    // Adjust for activity level
    if (data.activityLevel == ActivityLevel.veryActive ||
        data.activityLevel == ActivityLevel.extremelyActive) {
      waterMl *= 1.2;
    }

    // Adjust for sports player
    if (data.personType == PersonType.sportsPlayer) {
      waterMl *= 1.15;
    }

    int waterGlasses = (waterMl / 250).round(); // 1 glass = 250ml

    return {
      'waterIntakeGlasses': waterGlasses,
      'dailyCalories': calories.round(),
    };
  }

  /// Save recommendations to appropriate services
  Future<void> saveRecommendations(Map<String, int> recommendations) async {
    try {
      // Save water intake goal
      await _waterIntakeService
          .setTargetGlasses(recommendations['waterIntakeGlasses']!);

      // Save daily calorie goal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyCaloriesKey, recommendations['dailyCalories']!);
    } catch (e) {
      print('Error saving recommendations: $e');
    }
  }

  /// Get daily calorie goal
  Future<int> getDailyCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyCaloriesKey) ?? 2000; // Default 2000 calories
  }

  /// Helper methods for string conversions
  String _getActivityLevelString(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary (little to no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active (light exercise 1-3 days/week)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active (moderate exercise 3-5 days/week)';
      case ActivityLevel.veryActive:
        return 'Very Active (hard exercise 6-7 days/week)';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active (very hard exercise, physical job, or training twice per day)';
    }
  }

  String _getGoalString(OverallGoal goal) {
    switch (goal) {
      case OverallGoal.loseWeight:
        return 'Lose Weight';
      case OverallGoal.gainMuscle:
        return 'Gain Muscle';
      case OverallGoal.maintain:
        return 'Maintain Current Weight';
      case OverallGoal.mentalWellbeing:
        return 'Focus on Mental Wellbeing';
    }
  }

  String _getDietTypeString(DietType diet) {
    switch (diet) {
      case DietType.none:
        return 'No specific diet';
      case DietType.vegetarian:
        return 'Vegetarian';
      case DietType.vegan:
        return 'Vegan';
      case DietType.keto:
        return 'Ketogenic';
      case DietType.paleo:
        return 'Paleo';
      case DietType.mediterranean:
        return 'Mediterranean';
      case DietType.lowCarb:
        return 'Low Carb';
      case DietType.lowFat:
        return 'Low Fat';
      case DietType.glutenFree:
        return 'Gluten Free';
      case DietType.dairyFree:
        return 'Dairy Free';
      case DietType.other:
        return 'Other';
    }
  }

  String _getTimeHorizonString(TimeHorizon horizon) {
    switch (horizon) {
      case TimeHorizon.oneMonth:
        return '1 Month';
      case TimeHorizon.threeMonths:
        return '3 Months';
      case TimeHorizon.sixMonths:
        return '6 Months';
      case TimeHorizon.oneYear:
        return '1 Year';
      case TimeHorizon.longTerm:
        return 'Long Term (1+ years)';
    }
  }

  double _getActivityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extremelyActive:
        return 1.9;
    }
  }

  /// Clear onboarding data (for testing or reset)
  Future<void> clearOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
    await prefs.remove(_onboardingCompleteKey);
  }
}
