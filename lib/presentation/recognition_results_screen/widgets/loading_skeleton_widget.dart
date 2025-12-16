import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  const LoadingSkeletonWidget({super.key});

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSkeletonItem({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    strokeWidth: 4,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Analyzing ingredients...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),

          // Skeleton header
          Text(
            'Recognized Ingredients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),

          // Skeleton chips
          Wrap(
            spacing: 2.w,
            runSpacing: 1.5.h,
            children: [
              _buildSkeletonItem(width: 28.w, height: 5.h),
              _buildSkeletonItem(width: 24.w, height: 5.h),
              _buildSkeletonItem(width: 32.w, height: 5.h),
              _buildSkeletonItem(width: 26.w, height: 5.h),
              _buildSkeletonItem(width: 30.w, height: 5.h),
              _buildSkeletonItem(width: 25.w, height: 5.h),
            ],
          ),

          SizedBox(height: 4.h),

          // Skeleton list items
          Column(
            children: List.generate(4, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Row(
                  children: [
                    _buildSkeletonItem(width: 15.w, height: 15.w),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonItem(width: 60.w, height: 2.h),
                          SizedBox(height: 1.h),
                          _buildSkeletonItem(width: 40.w, height: 1.5.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
