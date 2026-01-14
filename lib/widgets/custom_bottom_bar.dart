import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for the bottom bar
enum CustomBottomBarItem {
  home(
    route: '/home-dashboard-screen',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  fitness(
    route: '/fitness-screen',
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center,
    label: 'Fitness',
  ),
  wellness(
    route: '/wellness-screen',
    icon: Icons.psychology_outlined,
    activeIcon: Icons.psychology,
    label: 'Wellness',
  ),
  chat(
    route: '/akira-chat-screen',
    icon: Icons.smart_toy_outlined,
    activeIcon: Icons.smart_toy,
    label: 'Chat',
  );

  const CustomBottomBarItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Custom bottom navigation bar with modern glassmorphic design
///
/// Features:
/// - Four primary navigation tabs (Home, Fitness, Wellness, Chat)
/// - Smooth animated transitions between tabs
/// - Glassmorphic blur effect with modern styling
/// - Haptic feedback on navigation
/// - Badge support for notifications
class CustomBottomBar extends StatefulWidget {
  /// Current active route
  final String currentRoute;

  /// Callback when navigation item is tapped
  final Function(String route)? onNavigate;

  /// Badge counts for each navigation item (optional)
  final Map<CustomBottomBarItem, int>? badges;

  /// Custom elevation for the bottom bar
  final double? elevation;

  const CustomBottomBar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
    this.badges,
    this.elevation,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _indicatorAnimationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _indicatorSlideAnimation;
  late Animation<double> _iconScaleAnimation;

  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = _getCurrentIndex();

    // Indicator slide animation
    _indicatorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _indicatorSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Icon scale animation with spring
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _indicatorAnimationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  int _getCurrentIndex() {
    final items = CustomBottomBarItem.values;
    for (int i = 0; i < items.length; i++) {
      if (widget.currentRoute.contains(items[i].route)) {
        return i;
      }
    }
    return 0;
  }

  void _handleNavigation(int index) {
    if (_previousIndex == index) return;

    HapticFeedback.lightImpact();

    // Trigger animations
    _indicatorAnimationController.reset();
    _indicatorAnimationController.forward();
    _iconAnimationController.reset();
    _iconAnimationController.forward();

    setState(() {
      _previousIndex = index;
    });

    final item = CustomBottomBarItem.values[index];
    if (widget.onNavigate != null) {
      widget.onNavigate!(item.route);
    } else {
      Navigator.pushNamed(context, item.route);
    }
  }

  Widget _buildBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex();
    final items = CustomBottomBarItem.values;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / items.length;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // iOS-style Bottom Navigation Bar
        ClipPath(
          clipper: _BottomBarClipper(),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.bottomNavigationBarTheme.backgroundColor
                          ?.withValues(alpha: 0.72) ??
                      theme.colorScheme.surface.withValues(alpha: 0.72),
                  border: Border(
                    top: BorderSide(
                      color: theme.brightness == Brightness.light
                          ? Colors.black.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 60,
                    child: Stack(
                      children: [
                        // iOS-style pill indicator
                        AnimatedBuilder(
                          animation: _indicatorSlideAnimation,
                          builder: (context, child) {
                          final targetPosition = currentIndex * itemWidth;
                          final startPosition = _previousIndex * itemWidth;
                          final currentPosition = startPosition +
                              (targetPosition - startPosition) *
                                  _indicatorSlideAnimation.value;

                          return Positioned(
                            left: currentPosition + (itemWidth - 64) / 2,
                            top: 8,
                            child: AnimatedOpacity(
                              opacity: _indicatorSlideAnimation.value,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 64,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.light
                                      ? Colors.black.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Navigation items
                      Row(
                        children: [
                          // All navigation items
                          ...List.generate(items.length, (index) {
                            final item = items[index];
                            final isSelected = currentIndex == index;
                            final badgeCount = widget.badges?[item] ?? 0;

                            return Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _handleNavigation(index),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Icon
                                        Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.center,
                                          children: [
                                            ScaleTransition(
                                              scale: isSelected &&
                                                      _iconAnimationController.isAnimating
                                                  ? _iconScaleAnimation
                                                  : const AlwaysStoppedAnimation(1.0),
                                              child: Icon(
                                                isSelected ? item.activeIcon : item.icon,
                                                size: 32,
                                                color: Colors.white,
                                              ),
                                            ),
                                            // Badge
                                            if (badgeCount > 0)
                                              Positioned(
                                                right: -8,
                                                top: -4,
                                                child: _buildBadge(badgeCount),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom clipper for bottom bar
class _BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Extension to easily check if a route is active
extension RouteExtension on String {
  bool isActiveRoute(String currentRoute) {
    return currentRoute.contains(this);
  }
}
