import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/nutrition_info.dart';
import './onboarding_service.dart';
import './water_intake_service.dart';
import '../models/user_onboarding_model.dart';

/// Firebase service for storing and retrieving daily nutrition data
///
/// Firestore Structure:
/// users/{userId}/daily_logs/{date}/
///   - calories: double
///   - protein: double
///   - carbs: double
///   - fat: double
///   - fiber: double
///   - sugar: double
///   - sodium: double
///   - waterGlasses: int
///   - foods: [array of logged food items]
///   - lastUpdated: timestamp
class FirebaseNutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For now, using a default user ID. In production, use Firebase Auth
  String get userId =>
      'default_user'; // TODO: Replace with Firebase Auth user ID

  /// Get date string in format: YYYY-MM-DD
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get reference to a specific date's document
  DocumentReference _getDateDocument(DateTime date) {
    final dateStr = _getDateString(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_logs')
        .doc(dateStr);
  }

  /// Initialize a new day's document with zeros
  Future<void> _initializeDay(DateTime date) async {
    final docRef = _getDateDocument(date);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'date': _getDateString(date),
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
        'sodium': 0.0,
        'waterGlasses': 0,
        'foods': [],
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Log a food item for a specific date
  Future<void> logFood({
    required NutritionInfo nutritionInfo,
    DateTime? date,
  }) async {
    try {
      print('📊 Starting food logging process...');
      final targetDate = date ?? DateTime.now();
      print('📅 Target date: ${_getDateString(targetDate)}');

      final docRef = _getDateDocument(targetDate);
      print('📄 Document path: ${docRef.path}');

      final foodData = nutritionInfo.toJson();
      print('🍎 Food data: ${foodData.toString()}');

      // Use DateTime.now() instead of FieldValue.serverTimestamp()
      // because FieldValue cannot be used in nested arrays
      foodData['loggedAt'] = DateTime.now().toIso8601String();

      // Validate that all required fields are non-null
      if (foodData['foodName'] == null ||
          foodData['calories'] == null ||
          foodData['protein'] == null ||
          foodData['carbs'] == null ||
          foodData['fat'] == null) {
        throw Exception('Missing required nutrition data fields');
      }

      print('🔄 Starting Firestore transaction...');
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        Map<String, dynamic> currentData;

        if (!snapshot.exists) {
          // Initialize the document within the transaction
          print('📝 Document does not exist, creating new document');
          currentData = {
            'date': _getDateString(targetDate),
            'calories': 0.0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'fiber': 0.0,
            'sugar': 0.0,
            'sodium': 0.0,
            'waterGlasses': 0,
            'foods': <Map<String, dynamic>>[],
            'createdAt': FieldValue.serverTimestamp(),
          };
        } else {
          currentData = snapshot.data() as Map<String, dynamic>;
          print('✅ Document exists, updating');
        }

        final currentCalories = (currentData['calories'] ?? 0.0).toDouble();
        final currentProtein = (currentData['protein'] ?? 0.0).toDouble();
        final currentCarbs = (currentData['carbs'] ?? 0.0).toDouble();
        final currentFat = (currentData['fat'] ?? 0.0).toDouble();
        final currentFiber = (currentData['fiber'] ?? 0.0).toDouble();
        final currentSugar = (currentData['sugar'] ?? 0.0).toDouble();
        final currentSodium = (currentData['sodium'] ?? 0.0).toDouble();
        final currentFoods =
            List<Map<String, dynamic>>.from(currentData['foods'] ?? []);

        // Add new food to the list
        currentFoods.add(foodData);

        // Prepare update data
        final updateData = {
          'date': _getDateString(targetDate),
          'calories': currentCalories + nutritionInfo.calories,
          'protein': currentProtein + nutritionInfo.protein,
          'carbs': currentCarbs + nutritionInfo.carbs,
          'fat': currentFat + nutritionInfo.fat,
          'fiber': currentFiber + nutritionInfo.fiber,
          'sugar': currentSugar + nutritionInfo.sugar,
          'sodium': currentSodium + nutritionInfo.sodium,
          'foods': currentFoods,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (!snapshot.exists) {
          updateData['createdAt'] = FieldValue.serverTimestamp();
          updateData['waterGlasses'] = 0;
          transaction.set(docRef, updateData);
          print('✅ Document created with new food');
        } else {
          transaction.update(docRef, updateData);
          print('✅ Document updated with new food');
        }
      });

      print('✅ Food logged successfully!');
    } catch (e, stackTrace) {
      print('❌ Error in logFood: $e');
      print('Stack trace: $stackTrace');
      // Re-throw with more context
      throw Exception('Failed to log food to Firestore: ${e.toString()}');
    }
  }

  /// Add a glass of water for a specific date
  Future<void> addWaterGlass({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    await _initializeDay(targetDate);

    final docRef = _getDateDocument(targetDate);

    await docRef.update({
      'waterGlasses': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a glass of water for a specific date
  Future<void> removeWaterGlass({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    await _initializeDay(targetDate);

    final docRef = _getDateDocument(targetDate);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      final currentWater = (data?['waterGlasses'] ?? 0) as int;
      if (currentWater > 0) {
        await docRef.update({
          'waterGlasses': FieldValue.increment(-1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Get daily totals for a specific date
  Future<Map<String, dynamic>> getDailyTotals({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    await _initializeDay(targetDate);

    final docRef = _getDateDocument(targetDate);
    final doc = await docRef.get();

    if (!doc.exists) {
      return {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
        'sodium': 0.0,
        'waterGlasses': 0,
        'foods': [],
      };
    }

    final data = doc.data() as Map<String, dynamic>;
    return {
      'calories': (data['calories'] ?? 0.0).toDouble(),
      'protein': (data['protein'] ?? 0.0).toDouble(),
      'carbs': (data['carbs'] ?? 0.0).toDouble(),
      'fat': (data['fat'] ?? 0.0).toDouble(),
      'fiber': (data['fiber'] ?? 0.0).toDouble(),
      'sugar': (data['sugar'] ?? 0.0).toDouble(),
      'sodium': (data['sodium'] ?? 0.0).toDouble(),
      'waterGlasses': (data['waterGlasses'] ?? 0) as int,
      'foods': data['foods'] ?? [],
    };
  }

  /// Get logged foods for a specific date
  Future<List<Map<String, dynamic>>> getLoggedFoods({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    await _initializeDay(targetDate);

    final docRef = _getDateDocument(targetDate);
    final doc = await docRef.get();

    if (!doc.exists) {
      return [];
    }

    final data = doc.data() as Map<String, dynamic>;
    final foods = data['foods'] as List<dynamic>?;

    if (foods == null) return [];

    return foods.map((food) => Map<String, dynamic>.from(food)).toList();
  }

  /// Delete a specific food item by index for a specific date
  Future<void> deleteFood({
    required int index,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final docRef = _getDateDocument(targetDate);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Document does not exist');
      }

      final currentData = snapshot.data() as Map<String, dynamic>;
      final foods = List<Map<String, dynamic>>.from(
        (currentData['foods'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e)),
      );

      if (index < 0 || index >= foods.length) {
        throw Exception('Invalid food index');
      }

      // Get the food being deleted
      final foodToDelete = foods[index];

      // Remove from totals
      final newCalories = (currentData['calories'] ?? 0.0).toDouble() -
          (foodToDelete['calories'] ?? 0.0).toDouble();
      final newProtein = (currentData['protein'] ?? 0.0).toDouble() -
          (foodToDelete['protein'] ?? 0.0).toDouble();
      final newCarbs = (currentData['carbs'] ?? 0.0).toDouble() -
          (foodToDelete['carbs'] ?? 0.0).toDouble();
      final newFat = (currentData['fat'] ?? 0.0).toDouble() -
          (foodToDelete['fat'] ?? 0.0).toDouble();
      final newFiber = (currentData['fiber'] ?? 0.0).toDouble() -
          (foodToDelete['fiber'] ?? 0.0).toDouble();
      final newSugar = (currentData['sugar'] ?? 0.0).toDouble() -
          (foodToDelete['sugar'] ?? 0.0).toDouble();
      final newSodium = (currentData['sodium'] ?? 0.0).toDouble() -
          (foodToDelete['sodium'] ?? 0.0).toDouble();

      // Remove food from list
      foods.removeAt(index);

      transaction.update(docRef, {
        'calories': newCalories.clamp(0, double.infinity),
        'protein': newProtein.clamp(0, double.infinity),
        'carbs': newCarbs.clamp(0, double.infinity),
        'fat': newFat.clamp(0, double.infinity),
        'fiber': newFiber.clamp(0, double.infinity),
        'sugar': newSugar.clamp(0, double.infinity),
        'sodium': newSodium.clamp(0, double.infinity),
        'foods': foods,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get data for multiple dates (for history view)
  Future<Map<String, Map<String, dynamic>>> getDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Map<String, Map<String, dynamic>> result = {};

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final dateStr = _getDateString(currentDate);
      final data = await getDailyTotals(date: currentDate);
      result[dateStr] = data;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  /// Set/update daily goals
  Future<void> setDailyGoals({
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    required int targetWaterGlasses,
  }) async {
    final goalsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('daily_goals');

    await goalsRef.set({
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'targetWaterGlasses': targetWaterGlasses,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get daily goals
  Future<Map<String, dynamic>> getDailyGoals() async {
    // First try to get goals from onboarding service
    final onboardingService = OnboardingService();
    final waterService = WaterIntakeService();

    final dailyCalories = await onboardingService.getDailyCalorieGoal();
    final targetWater = await waterService.getTargetGlasses();

    // Check if user has completed onboarding for personalized goals
    final hasOnboarding = await onboardingService.hasCompletedOnboarding();

    if (hasOnboarding) {
      // Use personalized goals from onboarding
      final onboardingData = await onboardingService.getOnboardingData();

      // Calculate macros based on calorie goal and overall goal
      double targetProtein = 150.0;
      double targetCarbs = 200.0;
      double targetFat = 70.0;

      if (onboardingData != null) {
        // Adjust macros based on goal
        switch (onboardingData.overallGoal) {
          case OverallGoal.loseWeight:
            // Higher protein, lower carbs for weight loss
            targetProtein = (dailyCalories * 0.30) / 4; // 30% protein, 4 cal/g
            targetCarbs = (dailyCalories * 0.40) / 4; // 40% carbs
            targetFat = (dailyCalories * 0.30) / 9; // 30% fat, 9 cal/g
            break;
          case OverallGoal.gainMuscle:
            // Higher protein and carbs for muscle gain
            targetProtein = (dailyCalories * 0.30) / 4; // 30% protein
            targetCarbs = (dailyCalories * 0.45) / 4; // 45% carbs
            targetFat = (dailyCalories * 0.25) / 9; // 25% fat
            break;
          case OverallGoal.maintain:
          case OverallGoal.mentalWellbeing:
            // Balanced macros
            targetProtein = (dailyCalories * 0.25) / 4; // 25% protein
            targetCarbs = (dailyCalories * 0.45) / 4; // 45% carbs
            targetFat = (dailyCalories * 0.30) / 9; // 30% fat
            break;
        }
      }

      return {
        'targetCalories': dailyCalories.toDouble(),
        'targetProtein': targetProtein,
        'targetCarbs': targetCarbs,
        'targetFat': targetFat,
        'targetWaterGlasses': targetWater,
      };
    }

    // Fallback to Firebase or default goals if no onboarding data
    final goalsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('daily_goals');

    final doc = await goalsRef.get();

    if (!doc.exists) {
      // Return default goals
      return {
        'targetCalories': dailyCalories.toDouble(),
        'targetProtein': 150.0,
        'targetCarbs': 200.0,
        'targetFat': 70.0,
        'targetWaterGlasses': targetWater,
      };
    }

    final data = doc.data()!;
    return {
      'targetCalories': (data['targetCalories'] ?? dailyCalories).toDouble(),
      'targetProtein': (data['targetProtein'] ?? 150.0).toDouble(),
      'targetCarbs': (data['targetCarbs'] ?? 200.0).toDouble(),
      'targetFat': (data['targetFat'] ?? 70.0).toDouble(),
      'targetWaterGlasses': (data['targetWaterGlasses'] ?? targetWater) as int,
    };
  }

  /// Get progress towards goals for a specific date
  Future<Map<String, double>> getProgress({DateTime? date}) async {
    final totals = await getDailyTotals(date: date);
    final goals = await getDailyGoals();

    return {
      'calories': goals['targetCalories'] > 0
          ? totals['calories'] / goals['targetCalories']
          : 0.0,
      'protein': goals['targetProtein'] > 0
          ? totals['protein'] / goals['targetProtein']
          : 0.0,
      'carbs': goals['targetCarbs'] > 0
          ? totals['carbs'] / goals['targetCarbs']
          : 0.0,
      'fat': goals['targetFat'] > 0 ? totals['fat'] / goals['targetFat'] : 0.0,
      'water': goals['targetWaterGlasses'] > 0
          ? totals['waterGlasses'] / goals['targetWaterGlasses']
          : 0.0,
    };
  }

  /// Stream daily totals for real-time updates
  Stream<Map<String, dynamic>> streamDailyTotals({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final docRef = _getDateDocument(targetDate);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {
          'calories': 0.0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'fiber': 0.0,
          'sugar': 0.0,
          'sodium': 0.0,
          'waterGlasses': 0,
          'foods': [],
        };
      }

      final data = snapshot.data() as Map<String, dynamic>;
      return {
        'calories': (data['calories'] ?? 0.0).toDouble(),
        'protein': (data['protein'] ?? 0.0).toDouble(),
        'carbs': (data['carbs'] ?? 0.0).toDouble(),
        'fat': (data['fat'] ?? 0.0).toDouble(),
        'fiber': (data['fiber'] ?? 0.0).toDouble(),
        'sugar': (data['sugar'] ?? 0.0).toDouble(),
        'sodium': (data['sodium'] ?? 0.0).toDouble(),
        'waterGlasses': (data['waterGlasses'] ?? 0) as int,
        'foods': data['foods'] ?? [],
      };
    });
  }
}
