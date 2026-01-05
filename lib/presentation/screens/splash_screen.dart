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
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();

    // Logo scale animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
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

    // Check if user has completed onboarding
    final hasCompletedOnboarding =
        await _onboardingService.hasCompletedOnboarding();

    if (!mounted) return;

    if (hasCompletedOnboarding) {
      // Navigate to home
      Navigator.of(context).pushReplacementNamed(AppRoutes.homeDashboard);
    } else {
      // Navigate to onboarding
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.white,
      body: Stack(
        children: [
          // Animated background circles
          _buildBackgroundCircles(isDark),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: _buildLogo(isDark),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App name with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDark
                          ? [Colors.cyan, Colors.blue]
                          : [const Color(0xFF6C63FF), const Color(0xFF4CAF50)],
                    ).createShader(bounds),
                    child: Text(
                      'NutriScan',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    'Your Personal Health Companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.cyan : const Color(0xFF6C63FF),
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
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.cyan.shade400, Colors.blue.shade600]
              : [const Color(0xFF6C63FF), const Color(0xFF4CAF50)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.cyan : const Color(0xFF6C63FF))
                .withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: 70,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBackgroundCircles(bool isDark) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -100,
          right: -100,
          child: _AnimatedCircle(
            size: 250,
            color: (isDark ? Colors.cyan : const Color(0xFF6C63FF))
                .withOpacity(0.1),
            duration: const Duration(seconds: 3),
          ),
        ),
        // Bottom left circle
        Positioned(
          bottom: -150,
          left: -150,
          child: _AnimatedCircle(
            size: 350,
            color: (isDark ? Colors.blue : const Color(0xFF4CAF50))
                .withOpacity(0.08),
            duration: const Duration(seconds: 4),
          ),
        ),
        // Middle circle
        Positioned(
          top: 150,
          left: -50,
          child: _AnimatedCircle(
            size: 200,
            color: (isDark ? Colors.purple : Colors.orange).withOpacity(0.06),
            duration: const Duration(milliseconds: 3500),
          ),
        ),
      ],
    );
  }
}

class _AnimatedCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _AnimatedCircle({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_AnimatedCircle> createState() => _AnimatedCircleState();
}

class _AnimatedCircleState extends State<_AnimatedCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
