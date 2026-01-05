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
  profile(
    route: '/user-profile-screen',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
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
/// - Four primary navigation tabs (Home, Log, Recipes, Profile)
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
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _indicatorSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Icon scale animation
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
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

    HapticFeedback.mediumImpact();

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

    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex();
    final items = CustomBottomBarItem.values;
    final itemWidth = MediaQuery.of(context).size.width / items.length;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Glassmorphic Bottom Navigation Bar
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.bottomNavigationBarTheme.backgroundColor
                        ?.withValues(alpha: 0.85) ??
                    theme.colorScheme.surface.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 68,
                  child: Stack(
                    children: [
                      // Animated indicator
                      AnimatedBuilder(
                        animation: _indicatorSlideAnimation,
                        builder: (context, child) {
                          final targetPosition = currentIndex * itemWidth;
                          final startPosition = _previousIndex * itemWidth;
                          final currentPosition = startPosition +
                              (targetPosition - startPosition) *
                                  _indicatorSlideAnimation.value;

                          return Positioned(
                            left: currentPosition + (itemWidth - 50) / 2,
                            top: 6,
                            child: AnimatedOpacity(
                              opacity: _indicatorSlideAnimation.value,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 50,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Navigation items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isSelected = currentIndex == index;
                          final badgeCount = widget.badges?[item] ?? 0;

                          return Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _handleNavigation(index),
                                splashColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                highlightColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOutCubic,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 4),
                                      // Icon with background
                                      Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          // Background circle
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOutCubic,
                                            width: isSelected ? 44 : 0,
                                            height: isSelected ? 44 : 0,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: isSelected
                                                  ? RadialGradient(
                                                      colors: [
                                                        theme
                                                            .colorScheme.primary
                                                            .withValues(
                                                                alpha: 0.15),
                                                        theme
                                                            .colorScheme.primary
                                                            .withValues(
                                                                alpha: 0.05),
                                                      ],
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          // Icon
                                          ScaleTransition(
                                            scale: isSelected &&
                                                    _iconAnimationController
                                                        .isAnimating
                                                ? _iconScaleAnimation
                                                : const AlwaysStoppedAnimation(
                                                    1.0),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOutCubic,
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                isSelected
                                                    ? item.activeIcon
                                                    : item.icon,
                                                size: isSelected ? 26 : 22,
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                        .bottomNavigationBarTheme
                                                        .unselectedItemColor,
                                              ),
                                            ),
                                          ),
                                          // Badge
                                          if (badgeCount > 0)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: _buildBadge(badgeCount),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Label
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: AnimatedDefaultTextStyle(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOutCubic,
                                          style: theme.textTheme.labelSmall!
                                              .copyWith(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.bottomNavigationBarTheme
                                                    .unselectedItemColor,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: isSelected ? 11 : 10,
                                            letterSpacing: 0.2,
                                            height: 1.0,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          child: AnimatedOpacity(
                                            opacity: isSelected ? 1.0 : 0.7,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: Text(
                                              item.label,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
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

/// Extension to easily check if a route is active
extension RouteExtension on String {
  bool isActiveRoute(String currentRoute) {
    return currentRoute.contains(this);
  }
}
