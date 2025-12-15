import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Profile header widget displaying user avatar, name, and streak information
class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userAvatar;
  final String avatarSemanticLabel;
  final int currentStreak;
  final VoidCallback onAvatarTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.avatarSemanticLabel,
    required this.currentStreak,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Avatar with edit indicator
          Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: userAvatar,
                      width: 25.w,
                      height: 25.w,
                      fit: BoxFit.cover,
                      semanticLabel: avatarSemanticLabel,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'edit',
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // User name
          Text(
            userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          // Streak counter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  '$currentStreak Day Streak',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
