import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Water intake tracker card widget
///
/// Displays water consumption with tap-to-increment glasses
/// Features visual glass indicators and progress tracking
class WaterIntakeCardWidget extends StatelessWidget {
  final int currentGlasses;
  final int targetGlasses;
  final VoidCallback? onAddGlass;
  final VoidCallback? onTap;

  const WaterIntakeCardWidget({
    super.key,
    required this.currentGlasses,
    required this.targetGlasses,
    this.onAddGlass,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentGlasses / targetGlasses).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
            theme.colorScheme.tertiary.withValues(alpha: 0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              border: Border.all(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.tertiary,
                                      theme.colorScheme.tertiary
                                          .withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.tertiary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.water_drop_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Water Intake',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '$currentGlasses / $targetGlasses glasses',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: progress),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Container(
                                  height: 12,
                                  width:
                                      MediaQuery.of(context).size.width * value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.tertiary,
                                        theme.colorScheme.tertiary
                                            .withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.tertiary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 2.w,
                              runSpacing: 1.h,
                              children: List.generate(
                                targetGlasses,
                                (index) => TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                      milliseconds: 400 + (index * 50)),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: CustomIconWidget(
                                        iconName: index < currentGlasses
                                            ? 'local_drink'
                                            : 'local_drink_outlined',
                                        color: index < currentGlasses
                                            ? theme.colorScheme.tertiary
                                            : theme.colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.3),
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Container(
                            decoration: BoxDecoration(
                              gradient: currentGlasses < targetGlasses
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.tertiary,
                                        theme.colorScheme.tertiary
                                            .withValues(alpha: 0.8),
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: currentGlasses < targetGlasses
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.tertiary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: currentGlasses < targetGlasses
                                  ? () {
                                      HapticFeedback.mediumImpact();
                                      onAddGlass?.call();
                                    }
                                  : null,
                              icon: Icon(
                                Icons.add_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                              label: Text(
                                'Add',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.5.h,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
