/// Custom painter for pose skeleton overlay.
/// Supports both live camera preview and high-DPI export for video frames.
import 'package:flutter/material.dart';
import '../models/keypoint.dart';
import '../utils/pose_utils.dart';

class PosePainter extends CustomPainter {
  final List<Keypoint> keypoints;
  final int? repCount;
  final String? exerciseType;
  final Color? lineColor;
  final Color? pointColor;
  final double lineWidth;
  final double pointRadius;
  final bool showLabels;
  final bool highDpi; // For export quality

  PosePainter({
    required this.keypoints,
    this.repCount,
    this.exerciseType,
    this.lineColor,
    this.pointColor,
    this.lineWidth = 3.0,
    this.pointRadius = 6.0,
    this.showLabels = false,
    this.highDpi = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;

    // Adjust line/point sizes for high-DPI export
    final effectiveLineWidth = highDpi ? lineWidth * 2 : lineWidth;
    final effectivePointRadius = highDpi ? pointRadius * 2 : pointRadius;

    // Determine colors based on exercise type
    final Color effectiveLineColor = lineColor ??
        (exerciseType != null
            ? PoseColors.forExerciseType(exerciseType!)
            : Colors.green);
    final Color effectivePointColor = pointColor ?? Colors.blue;

    PoseUtils.drawPoseSkeleton(
      canvas: canvas,
      size: size,
      keypoints: keypoints,
      repCount: repCount,
      lineColor: effectiveLineColor,
      pointColor: effectivePointColor,
      lineWidth: effectiveLineWidth,
      pointRadius: effectivePointRadius,
      showLabels: showLabels,
    );
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return keypoints != oldDelegate.keypoints ||
        repCount != oldDelegate.repCount ||
        exerciseType != oldDelegate.exerciseType;
  }
}

/// Overlay widget that wraps PosePainter for easy integration
class PoseOverlay extends StatelessWidget {
  final List<Keypoint> keypoints;
  final int? repCount;
  final String? exerciseType;
  final Color? lineColor;
  final Color? pointColor;
  final bool showLabels;

  const PoseOverlay({
    super.key,
    required this.keypoints,
    this.repCount,
    this.exerciseType,
    this.lineColor,
    this.pointColor,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PosePainter(
        keypoints: keypoints,
        repCount: repCount,
        exerciseType: exerciseType,
        lineColor: lineColor,
        pointColor: pointColor,
        showLabels: showLabels,
      ),
      child: Container(),
    );
  }
}
