import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/user_onboarding_model.dart';
import '../../services/onboarding_service.dart';
import '../../services/user_preferences_service.dart';
import '../../services/presidential_fitness_benchmarks.dart';
import '../../routes/app_routes.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  final UserPreferencesService _userPrefsService = UserPreferencesService();

  int _currentPage = 0;
  bool _isLoading = false;

  // Form data
  String _name = '';
  DateTime? _birthdate;
  String _gender = 'male';
  double? _heightCm;
  double? _weightKg;
  OverallGoal _overallGoal = OverallGoal.maintain;
  TimeHorizon _timeHorizon = TimeHorizon.threeMonths;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  List<String> _exercisePreferences = [];
  List<String> _equipment = [];
  DietType? _dietType;
  List<String> _allergies = [];
  List<String> _dislikes = [];
  CaloricTargetPreference _caloricTargetPreference =
      CaloricTargetPreference.automatic;
  int? _manualCaloricTarget;
  PersonType _personType = PersonType.normal;
  String? _sport;

  // Form keys
  final _nameFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  // ignore: unused_field
  final _goalFormKey = GlobalKey<FormState>();
  // ignore: unused_field
  final _activityFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      // Create onboarding model
      final onboardingData = UserOnboardingModel(
        name: _name,
        birthdate: _birthdate!,
        gender: _gender,
        heightCm: _heightCm!,
        weightKg: _weightKg!,
        overallGoal: _overallGoal,
        timeHorizon: _timeHorizon,
        activityLevel: _activityLevel,
        exercisePreferences: _exercisePreferences,
        equipment: _equipment,
        dietType: _dietType,
        allergies: _allergies,
        dislikes: _dislikes,
        caloricTargetPreference: _caloricTargetPreference,
        manualCaloricTarget: _manualCaloricTarget,
        personType: _personType,
        sport: _sport,
      );

      // Save onboarding data
      await _onboardingService.saveOnboardingData(onboardingData);

      // Save age and gender for Presidential Fitness Test evaluations
      final age = DateTime.now().year - _birthdate!.year;
      final gender = _gender == 'male' ? Gender.male : Gender.female;
      await _userPrefsService.saveAge(age);
      await _userPrefsService.saveGender(gender);
      print('✅ Saved fitness profile: Age=$age, Gender=$_gender');

      // Get personalized recommendations from Gemini
      Map<String, int> recommendations;
      try {
        recommendations =
            await _onboardingService.getPersonalizedRecommendations(
          onboardingData,
          AppConfig.geminiApiKey,
        );
      } catch (e) {
        print('Error getting Gemini recommendations, using defaults: $e');
        // If Gemini fails, use default calculations
        recommendations = {
          'waterIntakeGlasses': 8,
          'dailyCalories': 2000,
        };
      }

      // Save recommendations
      await _onboardingService.saveRecommendations(recommendations);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Profile created! Daily goals: ${recommendations['dailyCalories']} cal, ${recommendations['waterIntakeGlasses']} glasses water'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to home
      Navigator.of(context).pushReplacementNamed(AppRoutes.homeDashboard);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to FitGrit AI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentPage + 1) / 5,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor,
                ),
              ),

              // Page indicator text
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Step ${_currentPage + 1} of 5',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildAccountBasicsPage(),
                    _buildBasicProfilePage(),
                    _buildGoalsPage(),
                    _buildActivityPage(),
                    _buildNutritionPage(),
                  ],
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentPage == 4 ? 'Complete' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _name.isNotEmpty;
      case 1:
        return _birthdate != null && _heightCm != null && _weightKg != null;
      case 2:
        return true; // Goals are pre-selected
      case 3:
        return true; // Activity level is pre-selected
      case 4:
        return true; // Nutrition is optional
      default:
        return false;
    }
  }

  Widget _buildAccountBasicsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _nameFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let\'s start with your name',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ll use this to personalize your experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (value) {
                setState(() => _name = value.trim());
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This information helps us calculate your personalized goals',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Birthdate
            ListTile(
              title: const Text('Birthdate'),
              subtitle: Text(
                _birthdate != null
                    ? DateFormat('MMM dd, yyyy').format(_birthdate!)
                    : 'Tap to select',
              ),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _birthdate = date);
                }
              },
            ),
            const Divider(),

            // Gender
            const SizedBox(height: 16),
            const Text(
              'Gender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _gender == 'male',
                  onSelected: (selected) {
                    if (selected) setState(() => _gender = 'male');
                  },
                ),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: _gender == 'female',
                  onSelected: (selected) {
                    if (selected) setState(() => _gender = 'female');
                  },
                ),
                ChoiceChip(
                  label: const Text('Other'),
                  selected: _gender == 'other',
                  onSelected: (selected) {
                    if (selected) setState(() => _gender = 'other');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Height
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'e.g., 170',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                setState(() => _heightCm = double.tryParse(value));
              },
            ),
            const SizedBox(height: 16),

            // Weight
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g., 70',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              onChanged: (value) {
                setState(() => _weightKg = double.tryParse(value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Goals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tell us what you want to achieve',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Overall Goal
          const Text(
            'What\'s your main goal?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildGoalOption(
            icon: Icons.trending_down,
            title: 'Lose Weight',
            subtitle: 'Create a caloric deficit',
            goal: OverallGoal.loseWeight,
          ),
          _buildGoalOption(
            icon: Icons.fitness_center,
            title: 'Gain Muscle',
            subtitle: 'Build strength and muscle mass',
            goal: OverallGoal.gainMuscle,
          ),
          _buildGoalOption(
            icon: Icons.balance,
            title: 'Maintain',
            subtitle: 'Keep current weight and fitness',
            goal: OverallGoal.maintain,
          ),
          _buildGoalOption(
            icon: Icons.self_improvement,
            title: 'Mental Wellbeing',
            subtitle: 'Focus on overall wellness',
            goal: OverallGoal.mentalWellbeing,
          ),
          const SizedBox(height: 32),

          // Time Horizon
          const Text(
            'Time Horizon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TimeHorizon>(
            value: _timeHorizon,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            items: const [
              DropdownMenuItem(
                  value: TimeHorizon.oneMonth, child: Text('1 Month')),
              DropdownMenuItem(
                  value: TimeHorizon.threeMonths, child: Text('3 Months')),
              DropdownMenuItem(
                  value: TimeHorizon.sixMonths, child: Text('6 Months')),
              DropdownMenuItem(
                  value: TimeHorizon.oneYear, child: Text('1 Year')),
              DropdownMenuItem(
                  value: TimeHorizon.longTerm,
                  child: Text('Long Term (1+ years)')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _timeHorizon = value);
            },
          ),

          const SizedBox(height: 32),

          // Person Type
          const Text(
            'Are you a sports player?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                label: const Text('Regular Person'),
                selected: _personType == PersonType.normal,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _personType = PersonType.normal;
                      _sport = null;
                    });
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Sports Player'),
                selected: _personType == PersonType.sportsPlayer,
                onSelected: (selected) {
                  if (selected)
                    setState(() => _personType = PersonType.sportsPlayer);
                },
              ),
            ],
          ),

          // Sport selection (if sports player)
          if (_personType == PersonType.sportsPlayer) ...[
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Which sport do you play?',
                hintText: 'e.g., Basketball, Soccer, Tennis',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              onChanged: (value) {
                setState(() => _sport = value.trim());
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required OverallGoal goal,
  }) {
    final isSelected = _overallGoal == goal;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isSelected
              ? const Color.fromRGBO(69, 197, 136, 1.0)
              : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        color: isSelected
            ? const Color.fromRGBO(69, 197, 136, 1.0)
            : (isDarkMode ? const Color(0xFF2E2E2E) : Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {
            setState(() => _overallGoal = goal);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.black.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? const Color(0xFF1C1C1C) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1C1C1C) : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? const Color(0xFF1C1C1C).withOpacity(0.8)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1C1C1C),
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity & Fitness',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Help us understand your activity level',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Activity Level
          const Text(
            'Weekly Activity Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityOption(
            title: 'Sedentary',
            subtitle: 'Little to no exercise',
            level: ActivityLevel.sedentary,
          ),
          _buildActivityOption(
            title: 'Lightly Active',
            subtitle: 'Light exercise 1-3 days/week',
            level: ActivityLevel.lightlyActive,
          ),
          _buildActivityOption(
            title: 'Moderately Active',
            subtitle: 'Moderate exercise 3-5 days/week',
            level: ActivityLevel.moderatelyActive,
          ),
          _buildActivityOption(
            title: 'Very Active',
            subtitle: 'Hard exercise 6-7 days/week',
            level: ActivityLevel.veryActive,
          ),
          _buildActivityOption(
            title: 'Extremely Active',
            subtitle: 'Very hard exercise or physical job',
            level: ActivityLevel.extremelyActive,
          ),
          const SizedBox(height: 32),

          // Exercise Preferences
          const Text(
            'Exercise Preferences (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Running',
              'Cycling',
              'Swimming',
              'Weightlifting',
              'Yoga',
              'Pilates',
              'HIIT',
              'Walking',
              'Dancing',
              'Sports'
            ].map((pref) {
              final isSelected = _exercisePreferences.contains(pref);
              return FilterChip(
                label: Text(pref),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _exercisePreferences.add(pref);
                    } else {
                      _exercisePreferences.remove(pref);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Equipment
          const Text(
            'Equipment Available (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Dumbbells',
              'Resistance Bands',
              'Yoga Mat',
              'Pull-up Bar',
              'Kettlebells',
              'Treadmill',
              'Exercise Bike',
              'None'
            ].map((equip) {
              final isSelected = _equipment.contains(equip);
              return FilterChip(
                label: Text(equip),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _equipment.add(equip);
                    } else {
                      _equipment.remove(equip);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOption({
    required String title,
    required String subtitle,
    required ActivityLevel level,
  }) {
    final isSelected = _activityLevel == level;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isSelected
              ? const Color.fromRGBO(69, 197, 136, 1.0)
              : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        color: isSelected
            ? const Color.fromRGBO(69, 197, 136, 1.0)
            : (isDarkMode ? const Color(0xFF2E2E2E) : Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {
            setState(() => _activityLevel = level);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1C1C1C) : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? const Color(0xFF1C1C1C).withOpacity(0.8)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1C1C1C),
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'These are optional but help us provide better recommendations',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Diet Type
          const Text(
            'Diet Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DietType>(
            value: _dietType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
            hint: const Text('Select diet type (optional)'),
            items: const [
              DropdownMenuItem(value: null, child: Text('None')),
              DropdownMenuItem(
                  value: DietType.vegetarian, child: Text('Vegetarian')),
              DropdownMenuItem(value: DietType.vegan, child: Text('Vegan')),
              DropdownMenuItem(value: DietType.keto, child: Text('Keto')),
              DropdownMenuItem(value: DietType.paleo, child: Text('Paleo')),
              DropdownMenuItem(
                  value: DietType.mediterranean, child: Text('Mediterranean')),
              DropdownMenuItem(
                  value: DietType.lowCarb, child: Text('Low Carb')),
              DropdownMenuItem(value: DietType.lowFat, child: Text('Low Fat')),
              DropdownMenuItem(
                  value: DietType.glutenFree, child: Text('Gluten Free')),
              DropdownMenuItem(
                  value: DietType.dairyFree, child: Text('Dairy Free')),
            ],
            onChanged: (value) {
              setState(() => _dietType = value);
            },
          ),
          const SizedBox(height: 24),

          // Caloric Target Preference
          const Text(
            'Calorie Goal Preference',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                label: const Text('Automatic (Recommended)'),
                selected: _caloricTargetPreference ==
                    CaloricTargetPreference.automatic,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _caloricTargetPreference =
                          CaloricTargetPreference.automatic;
                      _manualCaloricTarget = null;
                    });
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Manual'),
                selected:
                    _caloricTargetPreference == CaloricTargetPreference.manual,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _caloricTargetPreference =
                        CaloricTargetPreference.manual);
                  }
                },
              ),
            ],
          ),

          // Manual caloric target (if manual preference)
          if (_caloricTargetPreference == CaloricTargetPreference.manual) ...[
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Daily Calorie Target',
                hintText: 'e.g., 2000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
                suffixText: 'cal',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                setState(() => _manualCaloricTarget = int.tryParse(value));
              },
            ),
          ],
          const SizedBox(height: 24),

          // Allergies (Optional)
          const Text(
            'Food Allergies (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'e.g., Peanuts, Shellfish (comma separated)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.warning_amber),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _allergies = value
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              });
            },
          ),
          const SizedBox(height: 16),

          // Dislikes (Optional)
          const Text(
            'Food Dislikes (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'e.g., Mushrooms, Olives (comma separated)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.thumb_down),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _dislikes = value
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              });
            },
          ),
        ],
      ),
    );
  }
}
