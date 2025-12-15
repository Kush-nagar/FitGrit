import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Privacy and security section with data management options
class PrivacySectionWidget extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onDeleteAccount;

  const PrivacySectionWidget({
    super.key,
    required this.onExportData,
    required this.onPrivacyPolicy,
    required this.onDeleteAccount,
  });

  Widget _buildPrivacyItem({
    required BuildContext context,
    required String label,
    required String iconName,
    required VoidCallback onTap,
    Color? textColor,
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
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: textColor ?? theme.colorScheme.onSurface,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
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
            'Privacy & Security',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        _buildPrivacyItem(
          context: context,
          label: 'Export My Data',
          iconName: 'download',
          onTap: onExportData,
        ),
        SizedBox(height: 1.h),
        _buildPrivacyItem(
          context: context,
          label: 'Privacy Policy',
          iconName: 'privacy_tip',
          onTap: onPrivacyPolicy,
        ),
        SizedBox(height: 1.h),
        _buildPrivacyItem(
          context: context,
          label: 'Delete Account',
          iconName: 'delete_forever',
          onTap: onDeleteAccount,
          textColor: theme.colorScheme.error,
        ),
      ],
    );
  }
}
