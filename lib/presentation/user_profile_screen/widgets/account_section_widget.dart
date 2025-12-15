import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Account information section with personal details
class AccountSectionWidget extends StatelessWidget {
  final int age;
  final String height;
  final String weight;
  final VoidCallback onEditAge;
  final VoidCallback onEditHeight;
  final VoidCallback onEditWeight;

  const AccountSectionWidget({
    super.key,
    required this.age,
    required this.height,
    required this.weight,
    required this.onEditAge,
    required this.onEditHeight,
    required this.onEditWeight,
  });

  Widget _buildInfoItem({
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            'Account Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        _buildInfoItem(
          context: context,
          label: 'Age',
          value: '$age years',
          onTap: onEditAge,
        ),
        SizedBox(height: 1.h),
        _buildInfoItem(
          context: context,
          label: 'Height',
          value: height,
          onTap: onEditHeight,
        ),
        SizedBox(height: 1.h),
        _buildInfoItem(
          context: context,
          label: 'Weight',
          value: weight,
          onTap: onEditWeight,
        ),
      ],
    );
  }
}
