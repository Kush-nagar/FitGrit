import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../routes/app_routes.dart';
import '../../services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();

    // Logo scale animation - smooth iOS-like entrance
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Shimmer animation for subtle shine effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start animations
    _logoController.forward();
    _fadeController.forward();

    // Check onboarding status and navigate
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Always navigate to animated intro screen after splash
    Navigator.of(context).pushReplacementNamed(AppRoutes.animatedIntro);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // iOS-style gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF000000),
                        const Color(0xFF0A0A0A),
                        const Color(0xFF000000),
                      ]
                    : [
                        const Color(0xFFFAFAFA),
                        const Color(0xFFF5F5F5),
                        const Color(0xFFFFFFFF),
                      ],
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with iOS-style design
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(isDark),
                  ),
                  const SizedBox(height: 40),

                  // App name with green gradient matching app theme
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFC4FF61),
                        Color(0xFF8BC34A),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'FitGrit AI',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline with iOS-style subtle text
                  Text(
                    'Your Personal Fitness & Wellness Companion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6C6C70),
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // iOS-style activity indicator at bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark
                          ? const Color(0xFF0A84FF)
                          : const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFF007AFF))
                    .withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Main logo container
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0A84FF),
                      const Color(0xFF5E5CE6),
                    ]
                  : [
                      const Color(0xFF007AFF),
                      const Color(0xFF5856D6),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer effect
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return ClipOval(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [
                            _shimmerAnimation.value - 0.3,
                            _shimmerAnimation.value,
                            _shimmerAnimation.value + 0.3,
                          ],
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Icon
              const Icon(
                Icons.fitness_center_rounded,
                size: 50,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
