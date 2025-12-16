import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class IngredientChipWidget extends StatelessWidget {
  final String ingredientName;
  final double confidence;
  final VoidCallback onRemove;
  final VoidCallback? onLongPress;

  const IngredientChipWidget({
    super.key,
    required this.ingredientName,
    required this.confidence,
    required this.onRemove,
    this.onLongPress,
  });

  Color _getConfidenceColor(BuildContext context) {
    final theme = Theme.of(context);

    if (confidence >= 0.8) {
      return theme.colorScheme.tertiary; // High confidence
    } else if (confidence >= 0.5) {
      return theme.colorScheme.secondary; // Medium confidence
    } else {
      return theme.colorScheme.error; // Low confidence
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _getConfidenceColor(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                ingredientName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: chipColor,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '${(confidence * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(0.5.w),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: chipColor,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
