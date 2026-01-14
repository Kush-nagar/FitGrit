import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../widgets/custom_bottom_bar.dart';
import '../../core/app_export.dart';
import '../../services/meditation_audio_service.dart';

/// Mental Wellness Screen
///
/// This screen serves as the main hub for mental wellness features
/// Features: mood check-in, breathing exercises, meditation, journaling, crisis resources
class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  double _currentMood = 3.0;
  String _moodNote = '';
  final TextEditingController _journalController = TextEditingController();

  final List<String> _moodEmojis = ['😢', '😔', '😐', '🙂', '😊'];
  final List<String> _moodLabels = ['Very Bad', 'Bad', 'Okay', 'Good', 'Great'];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _showMoodCheckIn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoodCheckInSheet(),
    );
  }

  void _showBreathingExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BreathingExerciseScreen(),
      ),
    );
  }

  void _showMeditations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeditationLibraryScreen(),
      ),
    );
  }

  void _showJournaling() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildJournalingSheet(),
    );
  }

  void _showCrisisResources() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CrisisResourcesScreen(),
      ),
    );
  }

  Widget _buildMoodCheckInSheet() {
    final theme = Theme.of(context);
    double tempMood = _currentMood;
    String tempNote = _moodNote;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 5.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'How are you feeling?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              // Mood emoji display
              Text(
                _moodEmojis[tempMood.round()],
                style: const TextStyle(fontSize: 80),
              ),
              SizedBox(height: 2.h),
              Text(
                _moodLabels[tempMood.round()],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 3.h),
              // Mood slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.primary.withOpacity(0.2),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14.0,
                  ),
                  trackHeight: 6.0,
                ),
                child: Slider(
                  value: tempMood,
                  min: 0,
                  max: 4,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() {
                      tempMood = value;
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
              SizedBox(height: 3.h),
              // Optional note
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.all(3.w),
                ),
                maxLines: 2,
                onChanged: (value) {
                  tempNote = value;
                },
              ),
              SizedBox(height: 3.h),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _currentMood = tempMood;
                      _moodNote = tempNote;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Mood logged successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Mood',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJournalingSheet() {
    final theme = Theme.of(context);
    final prompts = [
      'One thing that went well today',
      'Something I\'m grateful for',
      'A person who made me smile',
      'A small win I had',
      'Something I learned about myself',
    ];
    final randomPrompt = prompts[DateTime.now().day % prompts.length];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 5.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              SizedBox(width: 2.w),
              Text(
                'Quick Journal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    randomPrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _journalController,
            decoration: InputDecoration(
              hintText: 'Write your thoughts here...',
              hintStyle: TextStyle(fontSize: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.all(3.w),
            ),
            maxLines: 6,
            style: const TextStyle(fontSize: 16),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_journalController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _journalController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Journal entry saved!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          if (badge != null) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.psychology_rounded,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            const Text('Mental Wellness'),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take a moment for yourself',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Small steps toward better mental health',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('🧘‍♀️', style: TextStyle(fontSize: 48)),
                  ],
                ),
              ),
              SizedBox(height: 3.h),

              // Crisis resources (always visible)
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: _showCrisisResources,
                  child: Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Need immediate help? Tap for crisis resources',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 3.h),

              Text(
                'Daily Check-In',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),

              // Mood check-in card
              _buildFeatureCard(
                title: 'Mood Check-In',
                subtitle: 'Track how you\'re feeling today',
                icon: Icons.mood_rounded,
                color: Colors.amber,
                onTap: _showMoodCheckIn,
                badge: '30 sec',
              ),

              SizedBox(height: 3.h),
              Text(
                'Quick Tools',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),

              // Breathing exercise
              _buildFeatureCard(
                title: 'Breathing Exercise',
                subtitle: 'Guided box breathing to reduce stress',
                icon: Icons.air_rounded,
                color: Colors.blue,
                onTap: _showBreathingExercise,
                badge: '2 min',
              ),

              // Meditation library
              _buildFeatureCard(
                title: 'Micro-Meditations',
                subtitle: 'Short guided meditations for calm & focus',
                icon: Icons.spa_rounded,
                color: Colors.purple,
                onTap: _showMeditations,
                badge: '1-10 min',
              ),

              // Journaling
              _buildFeatureCard(
                title: 'Quick Journal',
                subtitle: 'Gratitude prompts & reflections',
                icon: Icons.edit_note_rounded,
                color: Colors.green,
                onTap: _showJournaling,
                badge: '2 min',
              ),

              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/wellness-screen',
        onNavigate: (route) {
          if (route != '/wellness-screen') {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}

// Breathing Exercise Screen
class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _phase = 0; // 0: Breathe In, 1: Hold, 2: Breathe Out, 3: Hold
  int _countdown = 4;
  int _cyclesCompleted = 0;
  final int _totalCycles = 3;
  bool _isActive = false;

  final List<String> _phaseNames = [
    'Breathe In',
    'Hold',
    'Breathe Out',
    'Hold'
  ];
  final List<int> _phaseDurations = [4, 4, 8, 4]; // Box breathing pattern

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isActive = true;
      _phase = 0;
      _countdown = _phaseDurations[0];
      _cyclesCompleted = 0;
    });
    _runPhase();
  }

  void _runPhase() {
    // Animate based on phase
    if (_phase == 0) {
      // Breathe in - expand
      _animationController.duration =
          Duration(seconds: _phaseDurations[_phase]);
      _animationController.forward(from: 0);
    } else if (_phase == 2) {
      // Breathe out - contract
      _animationController.duration =
          Duration(seconds: _phaseDurations[_phase]);
      _animationController.reverse(from: 1);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    setState(() {
      _phase++;
      if (_phase >= 4) {
        _phase = 0;
        _cyclesCompleted++;
        if (_cyclesCompleted >= _totalCycles) {
          _completeExercise();
          return;
        }
      }
      _countdown = _phaseDurations[_phase];
    });
    _runPhase();
  }

  void _completeExercise() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
    });
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Job! 🎉'),
        content: const Text(
            'You\'ve completed the breathing exercise. How do you feel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Breathing Exercise'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isActive) ...[
              Icon(
                Icons.air_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 3.h),
              Text(
                'Box Breathing',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  'A simple 4-4-8 breathing pattern to help reduce stress and anxiety.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              ElevatedButton(
                onPressed: _startExercise,
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Start Exercise',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              Text(
                'Cycle ${_cyclesCompleted + 1} of $_totalCycles',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 5.h),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 60.w * _scaleAnimation.value,
                    height: 60.w * _scaleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.6),
                          theme.colorScheme.primary.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                          fontSize: 72,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 5.h),
              Text(
                _phaseNames[_phase],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Meditation Library Screen
class MeditationLibraryScreen extends StatefulWidget {
  const MeditationLibraryScreen({super.key});

  @override
  State<MeditationLibraryScreen> createState() =>
      _MeditationLibraryScreenState();
}

class _MeditationLibraryScreenState extends State<MeditationLibraryScreen> {
  final MeditationAudioService _audioService = MeditationAudioService();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    
    // Listen to player state changes
    _audioService.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playingId = _audioService.currentMeditationId;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  Future<void> _playMeditation(String id, String title, int durationMinutes) async {
    if (_playingId == id && _audioService.isPlaying) {
      // If already playing this meditation, pause it
      await _audioService.pause();
      setState(() {
        _playingId = null;
      });
    } else {
      // Play the meditation
      await _audioService.playMeditation(id, durationMinutes);
      setState(() {
        _playingId = id;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing: $title - ${durationMinutes}min'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Stop',
              onPressed: () {
                _audioService.stop();
                setState(() {
                  _playingId = null;
                });
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meditations = [
      {
        'id': 'quick_calm',
        'title': 'Quick Calm',
        'duration': 1,
        'intent': 'Reduce Anxiety',
        'icon': Icons.self_improvement,
        'color': Colors.blue,
      },
      {
        'id': 'focus_boost',
        'title': 'Focus Boost',
        'duration': 3,
        'intent': 'Improve Focus',
        'icon': Icons.center_focus_strong,
        'color': Colors.orange,
      },
      {
        'id': 'stress_relief',
        'title': 'Stress Relief',
        'duration': 5,
        'intent': 'Stress Management',
        'icon': Icons.spa_rounded,
        'color': Colors.purple,
      },
      {
        'id': 'sleep_winddown',
        'title': 'Sleep Wind-Down',
        'duration': 10,
        'intent': 'Better Sleep',
        'icon': Icons.bedtime_rounded,
        'color': Colors.indigo,
      },
      {
        'id': 'body_scan',
        'title': 'Body Scan',
        'duration': 7,
        'intent': 'Relaxation',
        'icon': Icons.accessible_forward,
        'color': Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Micro-Meditations'),
        actions: [
          if (_audioService.isPlaying)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                _audioService.stop();
                setState(() {
                  _playingId = null;
                });
              },
              tooltip: 'Stop playback',
            ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: meditations.length,
        itemBuilder: (context, index) {
          final meditation = meditations[index];
          final isPlaying = _playingId == meditation['id'];
          
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  _playMeditation(
                    meditation['id'] as String,
                    meditation['title'] as String,
                    meditation['duration'] as int,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPlaying
                          ? (meditation['color'] as Color).withOpacity(0.5)
                          : theme.colorScheme.outline.withOpacity(0.2),
                      width: isPlaying ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color:
                              (meditation['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          meditation['icon'] as IconData,
                          color: meditation['color'] as Color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meditation['title'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${meditation['duration']} min',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (meditation['color'] as Color)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    meditation['intent'] as String,
                                    style: TextStyle(
                                      color: meditation['color'] as Color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: meditation['color'] as Color,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Crisis Resources Screen
class CrisisResourcesScreen extends StatelessWidget {
  const CrisisResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resources = [
      {
        'name': 'National Suicide Prevention Lifeline',
        'number': '988',
        'available': '24/7',
        'description': 'Free and confidential support',
      },
      {
        'name': 'Crisis Text Line',
        'number': 'Text HOME to 741741',
        'available': '24/7',
        'description': 'Text-based crisis support',
      },
      {
        'name': 'SAMHSA National Helpline',
        'number': '1-800-662-4357',
        'available': '24/7',
        'description': 'Mental health & substance abuse',
      },
      {
        'name': 'Veterans Crisis Line',
        'number': '988 then press 1',
        'available': '24/7',
        'description': 'Support for veterans',
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Crisis Resources'),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emergency,
                  color: Colors.red.shade700,
                  size: 48,
                ),
                SizedBox(height: 2.h),
                Text(
                  'If you\'re in immediate danger, call 911',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Crisis Helplines',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          ...resources.map((resource) {
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource['name']!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        resource['number']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${resource['description']} • ${resource['available']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'You\'re Not Alone',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  'These resources are free, confidential, and available 24/7. Trained counselors are ready to help you through difficult moments.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
