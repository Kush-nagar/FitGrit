/// Utility functions for pose drawing and frame annotation.
/// Used for both live overlay and video export.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/keypoint.dart';

class PoseUtils {
  /// Draw pose skeleton on canvas
  /// [canvas]: Flutter canvas to draw on
  /// [size]: Canvas size
  /// [keypoints]: List of detected keypoints
  /// [repCount]: Current rep count to display
  /// [lineColor]: Skeleton line color
  /// [pointColor]: Keypoint circle color
  /// [lineWidth]: Skeleton line width
  /// [pointRadius]: Keypoint circle radius
  static void drawPoseSkeleton({
    required Canvas canvas,
    required Size size,
    required List<Keypoint> keypoints,
    int? repCount,
    Color? lineColor,
    Color? pointColor,
    double lineWidth = 4.0,
    double pointRadius = 7.0,
    bool showLabels = false,
  }) {
    if (keypoints.isEmpty) return;

    // Use modern theme colors by default
    final effectiveLineColor = lineColor ?? PoseColors.primaryLime;
    final effectivePointColor = pointColor ?? const Color(0xFF6A6AED);

    final linePaint = Paint()
      ..color = effectiveLineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = effectivePointColor
      ..style = PaintingStyle.fill;

    // Add glow effect for points
    final glowPaint = Paint()
      ..color = effectivePointColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw skeleton connections
    for (final connection in KeypointNames.connections) {
      final start = _findKeypoint(keypoints, connection[0]);
      final end = _findKeypoint(keypoints, connection[1]);

      if (start != null && end != null) {
        final p1 = Offset(start.x * size.width, start.y * size.height);
        final p2 = Offset(end.x * size.width, end.y * size.height);
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    // Draw keypoints with glow
    for (final kp in keypoints) {
      final center = Offset(kp.x * size.width, kp.y * size.height);

      // Draw glow
      canvas.drawCircle(center, pointRadius * 2, glowPaint);

      // Draw point
      canvas.drawCircle(center, pointRadius, pointPaint);

      // Draw inner highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, pointRadius * 0.5, highlightPaint);

      // Optional: draw keypoint labels with better styling
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: kp.name.split('_').last,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(center.dx + 10, center.dy - 8),
        );
      }
    }
  }

  /// Render annotated frame to PNG bytes for export
  /// [frameRgb]: Original frame RGB bytes
  /// [keypoints]: Detected pose keypoints
  /// [width], [height]: Frame dimensions
  /// [repCount]: Rep count to overlay
  /// [timestampMillis]: Frame timestamp (optional, for debug)
  /// Returns PNG-encoded bytes
  static Future<Uint8List> renderAnnotatedFrame({
    required Uint8List frameRgb,
    required List<Keypoint> keypoints,
    required int width,
    required int height,
    int? repCount,
    int? timestampMillis,
  }) async {
    // Decode original frame
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: frameRgb.buffer,
      numChannels: 3,
    );

    // Draw skeleton on image
    final annotated = _drawSkeletonOnImage(
      image,
      keypoints,
      repCount: repCount,
    );

    // Encode to PNG
    return Uint8List.fromList(img.encodePng(annotated));
  }

  /// Draw skeleton directly on img.Image (for export)
  static img.Image _drawSkeletonOnImage(
    img.Image image,
    List<Keypoint> keypoints, {
    int? repCount,
  }) {
    final width = image.width;
    final height = image.height;

    // Draw connections with modern lime color
    for (final connection in KeypointNames.connections) {
      final start = _findKeypoint(keypoints, connection[0]);
      final end = _findKeypoint(keypoints, connection[1]);

      if (start != null && end != null) {
        final x1 = (start.x * width).toInt();
        final y1 = (start.y * height).toInt();
        final x2 = (end.x * width).toInt();
        final y2 = (end.y * height).toInt();

        img.drawLine(
          image,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: img.ColorRgb8(69, 197, 136), // Modern lime theme color
          thickness: 4,
        );
      }
    }

    // Draw keypoints with modern purple accent
    for (final kp in keypoints) {
      final x = (kp.x * width).toInt();
      final y = (kp.y * height).toInt();

      img.fillCircle(
        image,
        x: x,
        y: y,
        radius: 8,
        color: img.ColorRgb8(106, 106, 237), // Modern purple accent
      );
    }

    // Draw rep count text with better styling
    if (repCount != null) {
      img.drawString(
        image,
        'REPS: $repCount',
        font: img.arial48,
        x: 30,
        y: 30,
        color: img.ColorRgb8(69, 197, 136), // Modern lime theme color
      );
    }

    return image;
  }

  /// Calculate bounding box for detected pose
  /// Returns Rect or null if no keypoints
  static Rect? calculatePoseBoundingBox(
    List<Keypoint> keypoints,
    Size canvasSize,
  ) {
    if (keypoints.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final kp in keypoints) {
      final x = kp.x * canvasSize.width;
      final y = kp.y * canvasSize.height;

      minX = minX < x ? minX : x;
      minY = minY < y ? minY : y;
      maxX = maxX > x ? maxX : x;
      maxY = maxY > y ? maxY : y;
    }

    // Add padding
    const padding = 20.0;
    return Rect.fromLTRB(
      (minX - padding).clamp(0, canvasSize.width),
      (minY - padding).clamp(0, canvasSize.height),
      (maxX + padding).clamp(0, canvasSize.width),
      (maxY + padding).clamp(0, canvasSize.height),
    );
  }

  /// Smooth keypoints using exponential moving average
  /// [current]: Current frame keypoints
  /// [previous]: Previous frame keypoints
  /// [alpha]: Smoothing factor (0.0 = all previous, 1.0 = all current)
  static List<Keypoint> smoothKeypoints({
    required List<Keypoint> current,
    required List<Keypoint> previous,
    double alpha = 0.5,
  }) {
    if (previous.isEmpty) return current;

    final smoothed = <Keypoint>[];

    for (final currKp in current) {
      final prevKp = _findKeypoint(previous, currKp.name);

      if (prevKp != null) {
        // Apply EMA smoothing
        final smoothedX = alpha * currKp.x + (1 - alpha) * prevKp.x;
        final smoothedY = alpha * currKp.y + (1 - alpha) * prevKp.y;
        final smoothedConf =
            alpha * currKp.confidence + (1 - alpha) * prevKp.confidence;

        smoothed.add(Keypoint(
          name: currKp.name,
          x: smoothedX,
          y: smoothedY,
          confidence: smoothedConf,
        ));
      } else {
        smoothed.add(currKp);
      }
    }

    return smoothed;
  }

  /// Convert Canvas drawing to image bytes (for UI overlay capture)
  /// This is a helper for capturing rendered overlay as image
  static Future<Uint8List?> captureCanvasAsImage({
    required Size size,
    required Function(Canvas, Size) drawFunction,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    drawFunction(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Keypoint? _findKeypoint(List<Keypoint> keypoints, String name) {
    try {
      return keypoints.firstWhere((kp) => kp.name == name);
    } catch (_) {
      return null;
    }
  }
}

// Modern color schemes for different exercise types matching app theme
class PoseColors {
  // Using app theme colors for better visual consistency
  static const Color primaryLime = Color.fromRGBO(69, 197, 136, 1.0);
  static const Color accentPurple = Color(0xFF6A6AED);
  static const Color accentOrange = Color(0xFFFF7F3F);
  static const Color accentBlue = Color.fromARGB(255, 3, 222, 238);

  static const Color pushUpColor = primaryLime;
  static const Color pullUpColor = accentBlue;
  static const Color sitUpColor = accentOrange;
  static const Color squatColor = accentPurple;

  static Color forExerciseType(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
      case 'push_up':
        return pushUpColor;
      case 'pullup':
      case 'pull_up':
        return pullUpColor;
      case 'situp':
      case 'sit_up':
        return sitUpColor;
      case 'squat':
        return squatColor;
      default:
        return primaryLime;
    }
  }
}
