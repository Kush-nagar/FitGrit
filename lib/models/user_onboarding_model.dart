enum OverallGoal {
  loseWeight,
  gainMuscle,
  maintain,
  mentalWellbeing,
}

enum ActivityLevel {
  sedentary, // Little to no exercise
  lightlyActive, // Light exercise 1-3 days/week
  moderatelyActive, // Moderate exercise 3-5 days/week
  veryActive, // Hard exercise 6-7 days/week
  extremelyActive, // Very hard exercise, physical job or training twice per day
}

enum DietType {
  none,
  vegetarian,
  vegan,
  keto,
  paleo,
  mediterranean,
  lowCarb,
  lowFat,
  glutenFree,
  dairyFree,
  other,
}

enum CaloricTargetPreference {
  automatic,
  manual,
}

enum TimeHorizon {
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  longTerm,
}

enum PersonType {
  normal,
  sportsPlayer,
}

/// Model to store all user onboarding data
class UserOnboardingModel {
  // Account basics
  final String name;

  // Basic profile
  final DateTime birthdate;
  final String gender; // 'male', 'female', 'other'
  final double heightCm;
  final double weightKg;

  // Goals & priorities
  final OverallGoal overallGoal;
  final TimeHorizon timeHorizon;

  // Activity + fitness baseline
  final ActivityLevel activityLevel;
  final List<String> exercisePreferences;
  final List<String> equipment;

  // Nutrition preferences
  final DietType? dietType;
  final List<String> allergies;
  final List<String> dislikes;
  final CaloricTargetPreference caloricTargetPreference;
  final int? manualCaloricTarget; // Only if preference is manual

  // Sports player info
  final PersonType personType;
  final String? sport; // Only if personType is sportsPlayer

  // Gemini recommendations (set after onboarding)
  int? recommendedWaterIntakeGlasses;
  int? recommendedDailyCalories;

  UserOnboardingModel({
    required this.name,
    required this.birthdate,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.overallGoal,
    required this.timeHorizon,
    required this.activityLevel,
    required this.exercisePreferences,
    required this.equipment,
    this.dietType,
    this.allergies = const [],
    this.dislikes = const [],
    this.caloricTargetPreference = CaloricTargetPreference.automatic,
    this.manualCaloricTarget,
    required this.personType,
    this.sport,
    this.recommendedWaterIntakeGlasses,
    this.recommendedDailyCalories,
  });

  /// Calculate age from birthdate
  int get age {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthdate': birthdate.toIso8601String(),
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'overallGoal': overallGoal.index,
      'timeHorizon': timeHorizon.index,
      'activityLevel': activityLevel.index,
      'exercisePreferences': exercisePreferences,
      'equipment': equipment,
      'dietType': dietType?.index,
      'allergies': allergies,
      'dislikes': dislikes,
      'caloricTargetPreference': caloricTargetPreference.index,
      'manualCaloricTarget': manualCaloricTarget,
      'personType': personType.index,
      'sport': sport,
      'recommendedWaterIntakeGlasses': recommendedWaterIntakeGlasses,
      'recommendedDailyCalories': recommendedDailyCalories,
    };
  }

  /// Create from JSON
  factory UserOnboardingModel.fromJson(Map<String, dynamic> json) {
    return UserOnboardingModel(
      name: json['name'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      gender: json['gender'] as String,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      overallGoal: OverallGoal.values[json['overallGoal'] as int],
      timeHorizon: TimeHorizon.values[json['timeHorizon'] as int],
      activityLevel: ActivityLevel.values[json['activityLevel'] as int],
      exercisePreferences:
          List<String>.from(json['exercisePreferences'] as List),
      equipment: List<String>.from(json['equipment'] as List),
      dietType: json['dietType'] != null
          ? DietType.values[json['dietType'] as int]
          : null,
      allergies: List<String>.from(json['allergies'] as List? ?? []),
      dislikes: List<String>.from(json['dislikes'] as List? ?? []),
      caloricTargetPreference: CaloricTargetPreference
          .values[json['caloricTargetPreference'] as int],
      manualCaloricTarget: json['manualCaloricTarget'] as int?,
      personType: PersonType.values[json['personType'] as int],
      sport: json['sport'] as String?,
      recommendedWaterIntakeGlasses:
          json['recommendedWaterIntakeGlasses'] as int?,
      recommendedDailyCalories: json['recommendedDailyCalories'] as int?,
    );
  }

  /// Copy with method for updating fields
  UserOnboardingModel copyWith({
    String? name,
    DateTime? birthdate,
    String? gender,
    double? heightCm,
    double? weightKg,
    OverallGoal? overallGoal,
    TimeHorizon? timeHorizon,
    ActivityLevel? activityLevel,
    List<String>? exercisePreferences,
    List<String>? equipment,
    DietType? dietType,
    List<String>? allergies,
    List<String>? dislikes,
    CaloricTargetPreference? caloricTargetPreference,
    int? manualCaloricTarget,
    PersonType? personType,
    String? sport,
    int? recommendedWaterIntakeGlasses,
    int? recommendedDailyCalories,
  }) {
    return UserOnboardingModel(
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      overallGoal: overallGoal ?? this.overallGoal,
      timeHorizon: timeHorizon ?? this.timeHorizon,
      activityLevel: activityLevel ?? this.activityLevel,
      exercisePreferences: exercisePreferences ?? this.exercisePreferences,
      equipment: equipment ?? this.equipment,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      dislikes: dislikes ?? this.dislikes,
      caloricTargetPreference:
          caloricTargetPreference ?? this.caloricTargetPreference,
      manualCaloricTarget: manualCaloricTarget ?? this.manualCaloricTarget,
      personType: personType ?? this.personType,
      sport: sport ?? this.sport,
      recommendedWaterIntakeGlasses:
          recommendedWaterIntakeGlasses ?? this.recommendedWaterIntakeGlasses,
      recommendedDailyCalories:
          recommendedDailyCalories ?? this.recommendedDailyCalories,
    );
  }
}
