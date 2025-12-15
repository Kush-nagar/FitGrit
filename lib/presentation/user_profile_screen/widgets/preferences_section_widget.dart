import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Dietary preferences section with toggles for restrictions
class PreferencesSectionWidget extends StatelessWidget {
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final bool isNutFree;
  final Function(bool) onVegetarianChanged;
  final Function(bool) onVeganChanged;
  final Function(bool) onGlutenFreeChanged;
  final Function(bool) onDairyFreeChanged;
  final Function(bool) onNutFreeChanged;

  const PreferencesSectionWidget({
    super.key,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.isDairyFree,
    required this.isNutFree,
    required this.onVegetarianChanged,
    required this.onVeganChanged,
    required this.onGlutenFreeChanged,
    required this.onDairyFreeChanged,
    required this.onNutFreeChanged,
  });

  Widget _buildPreferenceToggle({
    required BuildContext context,
    required String label,
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
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
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
            'Dietary Preferences',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        _buildPreferenceToggle(
          context: context,
          label: 'Vegetarian',
          value: isVegetarian,
          onChanged: onVegetarianChanged,
        ),
        SizedBox(height: 1.h),
        _buildPreferenceToggle(
          context: context,
          label: 'Vegan',
          value: isVegan,
          onChanged: onVeganChanged,
        ),
        SizedBox(height: 1.h),
        _buildPreferenceToggle(
          context: context,
          label: 'Gluten-Free',
          value: isGlutenFree,
          onChanged: onGlutenFreeChanged,
        ),
        SizedBox(height: 1.h),
        _buildPreferenceToggle(
          context: context,
          label: 'Dairy-Free',
          value: isDairyFree,
          onChanged: onDairyFreeChanged,
        ),
        SizedBox(height: 1.h),
        _buildPreferenceToggle(
          context: context,
          label: 'Nut-Free',
          value: isNutFree,
          onChanged: onNutFreeChanged,
        ),
      ],
    );
  }
}
