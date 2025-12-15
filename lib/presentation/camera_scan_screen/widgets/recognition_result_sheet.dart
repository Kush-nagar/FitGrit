import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';

class RecognitionResultSheet extends StatefulWidget {
  final String foodName;
  final double confidence;
  final int calories;
  final String imagePath;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onManualEntry;

  const RecognitionResultSheet({
    super.key,
    required this.foodName,
    required this.confidence,
    required this.calories,
    required this.imagePath,
    required this.onConfirm,
    required this.onEdit,
    required this.onManualEntry,
  });

  @override
  State<RecognitionResultSheet> createState() => _RecognitionResultSheetState();
}

class _RecognitionResultSheetState extends State<RecognitionResultSheet> {
  double _portionMultiplier = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adjustedCalories = (widget.calories * _portionMultiplier).round();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recognition Result',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Food Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: kIsWeb
                          ? Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: 'image',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 48,
                                ),
                              ),
                            )
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Food Name and Confidence
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.foodName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: widget.confidence >= 0.8
                                      ? 'check_circle'
                                      : widget.confidence >= 0.5
                                          ? 'warning'
                                          : 'error_outline',
                                  color: widget.confidence >= 0.8
                                      ? AppTheme.primaryLime
                                      : widget.confidence >= 0.5
                                          ? AppTheme.accentOrange
                                          : AppTheme.accentRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(widget.confidence * 100).toInt()}% confidence',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Calorie Information
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Calories',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$adjustedCalories kcal',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        CustomIconWidget(
                          iconName: 'local_fire_department',
                          color: theme.colorScheme.primary,
                          size: 40,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Portion Size Adjustment
                  Text(
                    'Adjust Portion Size',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'remove_circle_outline',
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        onPressed: _portionMultiplier > 0.25
                            ? () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _portionMultiplier =
                                      (_portionMultiplier - 0.25)
                                          .clamp(0.25, 3.0);
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${(_portionMultiplier * 100).toInt()}%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPortionLabel(_portionMultiplier),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'add_circle_outline',
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        onPressed: _portionMultiplier < 3.0
                            ? () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _portionMultiplier =
                                      (_portionMultiplier + 0.25)
                                          .clamp(0.25, 3.0);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor:
                          theme.colorScheme.surfaceContainerHighest,
                      thumbColor: theme.colorScheme.primary,
                      overlayColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _portionMultiplier,
                      min: 0.25,
                      max: 3.0,
                      divisions: 11,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _portionMultiplier = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onEdit,
                          icon: CustomIconWidget(
                            iconName: 'edit',
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: widget.onConfirm,
                          icon: CustomIconWidget(
                            iconName: 'check',
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                          label: const Text('Confirm & Log'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Manual Entry Option
                  if (widget.confidence < 0.8)
                    TextButton.icon(
                      onPressed: widget.onManualEntry,
                      icon: CustomIconWidget(
                        iconName: 'edit_note',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      label: const Text('Switch to Manual Entry'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPortionLabel(double multiplier) {
    if (multiplier <= 0.5) return 'Small portion';
    if (multiplier <= 0.75) return 'Half portion';
    if (multiplier <= 1.25) return 'Standard portion';
    if (multiplier <= 1.75) return 'Large portion';
    return 'Extra large portion';
  }
}
