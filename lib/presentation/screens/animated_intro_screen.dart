import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../routes/app_routes.dart';
import '../../services/onboarding_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedIntroScreen extends StatefulWidget {
  const AnimatedIntroScreen({super.key});

  @override
  State<AnimatedIntroScreen> createState() => _AnimatedIntroScreenState();
}

class _AnimatedIntroScreenState extends State<AnimatedIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _presidentController;
  late AnimationController _executiveOrderController;
  late AnimationController _nutritionController;
  late AnimationController _wellnessController;
  late AnimationController _aiController;
  late AnimationController _welcomeController;

  late Animation<Offset> _presidentSlideIn;
  late Animation<Offset> _presidentSlideOut;
  late Animation<Offset> _executiveOrderSlideIn;
  late Animation<Offset> _executiveOrderSlideOut;
  late Animation<Offset> _nutritionSlideIn;
  late Animation<Offset> _nutritionSlideOut;
  late Animation<Offset> _wellnessSlideIn;
  late Animation<Offset> _wellnessSlideOut;
  late Animation<Offset> _aiSlideIn;
  late Animation<Offset> _aiSlideOut;

  late Animation<double> _welcomeFade;
  late Animation<double> _welcomeScale;

  late Animation<double> _presidentOpacity;
  late Animation<double> _executiveOrderOpacity;
  late Animation<double> _nutritionOpacity;
  late Animation<double> _wellnessOpacity;
  late Animation<double> _aiOpacity;

  bool _showPresident = false;
  bool _showExecutiveOrder = false;
  bool _showNutrition = false;
  bool _showWellness = false;
  bool _showAI = false;
  bool _showWelcome = false;

  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Presidential Logo Animation (White House)
    _presidentController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _presidentSlideIn = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _presidentController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart),
    ));

    _presidentSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _presidentController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInQuart),
    ));

    _presidentOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
    ]).animate(_presidentController);

    // Executive Order Logo Animation
    _executiveOrderController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _executiveOrderSlideIn = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _executiveOrderController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart),
    ));

    _executiveOrderSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _executiveOrderController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInQuart),
    ));

    _executiveOrderOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
    ]).animate(_executiveOrderController);

    // Nutrition Logo Animation
    _nutritionController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _nutritionSlideIn = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _nutritionController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart),
    ));

    _nutritionSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _nutritionController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInQuart),
    ));

    _nutritionOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
    ]).animate(_nutritionController);

    // Wellness Logo Animation
    _wellnessController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _wellnessSlideIn = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _wellnessController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart),
    ));

    _wellnessSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _wellnessController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInQuart),
    ));

    _wellnessOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
    ]).animate(_wellnessController);

    // AI Logo Animation
    _aiController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _aiSlideIn = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _aiController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutQuart),
    ));

    _aiSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _aiController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInQuart),
    ));

    _aiOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 35),
    ]).animate(_aiController);

    // Welcome Text Animation
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _welcomeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeInOutQuad,
      ),
    );

    _welcomeScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Presidential Logo
    setState(() => _showPresident = true);
    await _presidentController.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    // Executive Order Logo
    setState(() {
      _showPresident = false;
      _showExecutiveOrder = true;
    });
    _presidentController.reset();
    await _executiveOrderController.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    // Nutrition Logo
    setState(() {
      _showExecutiveOrder = false;
      _showNutrition = true;
    });
    _executiveOrderController.reset();
    await _nutritionController.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    // Wellness Logo
    setState(() {
      _showNutrition = false;
      _showWellness = true;
    });
    _nutritionController.reset();
    await _wellnessController.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    // AI Logo
    setState(() {
      _showWellness = false;
      _showAI = true;
    });
    _wellnessController.reset();
    await _aiController.forward();

    // Welcome Text
    setState(() {
      _showAI = false;
      _showWelcome = true;
    });
    _aiController.reset();
    await _welcomeController.forward();

    // Navigate to next screen based on onboarding status
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check if user has completed onboarding
      final hasCompletedOnboarding =
          await _onboardingService.hasCompletedOnboarding();

      if (!mounted) return;

      if (hasCompletedOnboarding) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.homeDashboard);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _presidentController.dispose();
    _executiveOrderController.dispose();
    _nutritionController.dispose();
    _wellnessController.dispose();
    _aiController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: Stack(
          children: [
            // Presidential Logo (White House)
            if (_showPresident)
              Center(
                child: AnimatedBuilder(
                  animation: _presidentController,
                  builder: (context, child) {
                    final slideOffset = _presidentController.value < 0.7
                        ? _presidentSlideIn.value
                        : _presidentSlideOut.value;

                    return Transform.translate(
                      offset: Offset(
                        slideOffset.dx * size.width,
                        slideOffset.dy * size.height,
                      ),
                      child: FadeTransition(
                        opacity: _presidentOpacity,
                        child: _buildPresidentialLogo(size),
                      ),
                    );
                  },
                ),
              ),

            // Executive Order Logo
            if (_showExecutiveOrder)
              Center(
                child: AnimatedBuilder(
                  animation: _executiveOrderController,
                  builder: (context, child) {
                    final slideOffset = _executiveOrderController.value < 0.7
                        ? _executiveOrderSlideIn.value
                        : _executiveOrderSlideOut.value;

                    return Transform.translate(
                      offset: Offset(
                        slideOffset.dx * size.width,
                        slideOffset.dy * size.height,
                      ),
                      child: FadeTransition(
                        opacity: _executiveOrderOpacity,
                        child: _buildExecutiveOrderLogo(size),
                      ),
                    );
                  },
                ),
              ),

            // Nutrition Logo
            if (_showNutrition)
              Center(
                child: AnimatedBuilder(
                  animation: _nutritionController,
                  builder: (context, child) {
                    final slideOffset = _nutritionController.value < 0.7
                        ? _nutritionSlideIn.value
                        : _nutritionSlideOut.value;

                    return Transform.translate(
                      offset: Offset(
                        slideOffset.dx * size.width,
                        slideOffset.dy * size.height,
                      ),
                      child: FadeTransition(
                        opacity: _nutritionOpacity,
                        child: _buildNutritionLogo(size),
                      ),
                    );
                  },
                ),
              ),

            // Wellness Logo
            if (_showWellness)
              Center(
                child: AnimatedBuilder(
                  animation: _wellnessController,
                  builder: (context, child) {
                    final slideOffset = _wellnessController.value < 0.7
                        ? _wellnessSlideIn.value
                        : _wellnessSlideOut.value;

                    return Transform.translate(
                      offset: Offset(
                        slideOffset.dx * size.width,
                        slideOffset.dy * size.height,
                      ),
                      child: FadeTransition(
                        opacity: _wellnessOpacity,
                        child: _buildWellnessLogo(size),
                      ),
                    );
                  },
                ),
              ),

            // AI Logo
            if (_showAI)
              Center(
                child: AnimatedBuilder(
                  animation: _aiController,
                  builder: (context, child) {
                    final slideOffset = _aiController.value < 0.7
                        ? _aiSlideIn.value
                        : _aiSlideOut.value;

                    return Transform.translate(
                      offset: Offset(
                        slideOffset.dx * size.width,
                        slideOffset.dy * size.height,
                      ),
                      child: FadeTransition(
                        opacity: _aiOpacity,
                        child: _buildAILogo(size),
                      ),
                    );
                  },
                ),
              ),

            // Welcome Text
            if (_showWelcome)
              Center(
                child: AnimatedBuilder(
                  animation: _welcomeController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _welcomeFade,
                      child: ScaleTransition(
                        scale: _welcomeScale,
                        child: Text(
                          'Welcome To Wellness Journey!',
                          style: GoogleFonts.righteous(
                            fontSize: 56,
                            letterSpacing: 4,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresidentialLogo(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.width * 0.6,
          height: size.width * 0.4,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF1a237e),
          ),
          child: Image.asset(
            'assets/images/pres.jpg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PRESIDENTIAL',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'WELLNESS INITIATIVE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveOrderLogo(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.width * 0.55,
          height: size.width * 0.55,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF8B0000),
          ),
          child: Image.asset(
            'assets/images/award.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PRESIDENTIAL PHYSICAL',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'FITNESS TEST',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ANALYSIS / REVIEWER',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionLogo(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.width * 0.45,
          height: size.width * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50),
          ),
          child: Stack(
            children: [
              // Apple icon
              Center(
                child: Icon(
                  Icons.apple,
                  size: size.width * 0.22,
                  color: Colors.white,
                ),
              ),
              // Leaf accent
              Positioned(
                top: size.width * 0.08,
                right: size.width * 0.15,
                child: Transform.rotate(
                  angle: -math.pi / 6,
                  child: Icon(
                    Icons.eco,
                    size: size.width * 0.1,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'NUTRITION',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SMART FOOD TRACKING',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessLogo(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.width * 0.45,
          height: size.width * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9C27B0),
          ),
          child: Stack(
            children: [
              // Heart with pulse
              Center(
                child: Icon(
                  Icons.favorite,
                  size: size.width * 0.22,
                  color: Colors.white,
                ),
              ),
              // Pulse line overlay
              Positioned(
                bottom: size.width * 0.14,
                left: size.width * 0.08,
                right: size.width * 0.08,
                child: CustomPaint(
                  size: Size(size.width * 0.29, 30),
                  painter: HeartbeatPainter(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'MENTAL WELLNESS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'HOLISTIC HEALTH',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAILogo(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.width * 0.45,
          height: size.width * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1976D2),
          ),
          child: Stack(
            children: [
              // Brain/AI icon
              Center(
                child: Icon(
                  Icons.psychology,
                  size: size.width * 0.22,
                  color: Colors.white,
                ),
              ),
              // Circuit nodes
              Positioned(
                top: size.width * 0.1,
                left: size.width * 0.1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: size.width * 0.08,
                right: size.width * 0.12,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: size.width * 0.12,
                left: size.width * 0.14,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white60,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'AI POWERED',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'INTELLIGENT COACHING',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Custom painter for heartbeat line
class HeartbeatPainter extends CustomPainter {
  final Color color;

  HeartbeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;

    // Flat line
    path.moveTo(0, midY);
    path.lineTo(width * 0.3, midY);

    // First spike
    path.lineTo(width * 0.35, midY - height * 0.4);
    path.lineTo(width * 0.4, midY + height * 0.3);

    // Second spike
    path.lineTo(width * 0.45, midY - height * 0.2);
    path.lineTo(width * 0.5, midY);

    // Flat line to end
    path.lineTo(width, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
