import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ConfidenceOverlayWidget extends StatelessWidget {
  final String foodName;
  final double confidence;

  const ConfidenceOverlayWidget({
    super.key,
    required this.foodName,
    required this.confidence,
  });

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppTheme.primaryLime;
    } else if (confidence >= 0.5) {
      return AppTheme.accentOrange;
    } else {
      return AppTheme.accentRed;
    }
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.8) {
      return Icons.check_circle;
    } else if (confidence >= 0.5) {
      return Icons.warning;
    } else {
      return Icons.error_outline;
    }
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'High Confidence';
    } else if (confidence >= 0.5) {
      return 'Medium Confidence';
    } else {
      return 'Low Confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidenceColor = _getConfidenceColor(confidence);
    final confidenceIcon = _getConfidenceIcon(confidence);
    final confidenceLabel = _getConfidenceLabel(confidence);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confidence Icon and Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: confidenceIcon.codePoint.toString(),
                color: confidenceColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '${(confidence * 100).toInt()}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: confidenceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Confidence Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: confidenceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              confidenceLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: confidenceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: theme.colorScheme.outline,
          ),

          const SizedBox(height: 16),

          // Food Name
          Row(
            children: [
              CustomIconWidget(
                iconName: 'restaurant',
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  foodName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 16),

          // Status Message
          Text(
            confidence >= 0.8
                ? 'Great match! Review details below.'
                : confidence >= 0.5
                    ? 'Possible match. Please verify details.'
                    : 'Low confidence. Consider manual entry.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
