import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// App settings section with notification, units, and theme preferences
class AppSettingsSectionWidget extends StatelessWidget {
  final bool notificationsEnabled;
  final bool useMetricUnits;
  final String selectedTheme;
  final Function(bool) onNotificationsChanged;
  final Function(bool) onUnitsChanged;
  final VoidCallback onThemePressed;

  const AppSettingsSectionWidget({
    super.key,
    required this.notificationsEnabled,
    required this.useMetricUnits,
    required this.selectedTheme,
    required this.onNotificationsChanged,
    required this.onUnitsChanged,
    required this.onThemePressed,
  });

  Widget _buildSettingToggle({
    required BuildContext context,
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'App Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        _buildSettingToggle(
          context: context,
          label: 'Notifications',
          subtitle: 'Meal reminders and goal tracking',
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        SizedBox(height: 1.h),
        _buildSettingToggle(
          context: context,
          label: 'Metric Units',
          subtitle: 'Use kg and cm instead of lbs and inches',
          value: useMetricUnits,
          onChanged: onUnitsChanged,
        ),
        SizedBox(height: 1.h),
        _buildSettingItem(
          context: context,
          label: 'Theme',
          value: selectedTheme,
          onTap: onThemePressed,
        ),
      ],
    );
  }
}
