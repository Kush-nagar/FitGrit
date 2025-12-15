import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CameraControlsWidget extends StatelessWidget {
  final bool isProcessing;
  final Animation<double> captureAnimation;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback? onRetake;

  const CameraControlsWidget({
    super.key,
    required this.isProcessing,
    required this.captureAnimation,
    required this.onCapture,
    required this.onGallery,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery Button
            _ControlButton(
              icon: 'photo_library',
              label: 'Gallery',
              onPressed: isProcessing ? null : onGallery,
            ),

            // Capture Button
            ScaleTransition(
              scale: captureAnimation,
              child: GestureDetector(
                onTap: isProcessing ? null : onCapture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isProcessing
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                    child: isProcessing
                        ? Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : Center(
                            child: CustomIconWidget(
                              iconName: 'camera_alt',
                              color: Colors.black,
                              size: 36,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Retake/Info Button
            _ControlButton(
              icon: onRetake != null ? 'refresh' : 'info_outline',
              label: onRetake != null ? 'Retake' : 'Tips',
              onPressed: isProcessing
                  ? null
                  : (onRetake ?? () => _showTipsDialog(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanning Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipItem(
              icon: 'wb_sunny',
              text: 'Ensure good lighting for best results',
            ),
            const SizedBox(height: 12),
            _TipItem(
              icon: 'center_focus_strong',
              text: 'Center the food in the frame',
            ),
            const SizedBox(height: 12),
            _TipItem(
              icon: 'straighten',
              text: 'Keep camera steady and at eye level',
            ),
            const SizedBox(height: 12),
            _TipItem(
              icon: 'zoom_out_map',
              text: 'Capture the entire dish if possible',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: isEnabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String icon;
  final String text;

  const _TipItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
