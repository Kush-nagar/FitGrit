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
    Color lineColor = Colors.green,
    Color pointColor = Colors.blue,
    double lineWidth = 3.0,
    double pointRadius = 6.0,
    bool showLabels = false,
  }) {
    if (keypoints.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

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

    // Draw keypoints
    for (final kp in keypoints) {
      final center = Offset(kp.x * size.width, kp.y * size.height);
      canvas.drawCircle(center, pointRadius, pointPaint);

      // Optional: draw keypoint labels
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: kp.name.split('_').last,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(center.dx + 8, center.dy - 5),
        );
      }
    }

    // Draw rep count overlay
    if (repCount != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Reps: $repCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, const Offset(20, 20));
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

    // Draw connections
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
          color: img.ColorRgb8(0, 255, 0), // Green
          thickness: 3,
        );
      }
    }

    // Draw keypoints
    for (final kp in keypoints) {
      final x = (kp.x * width).toInt();
      final y = (kp.y * height).toInt();

      img.fillCircle(
        image,
        x: x,
        y: y,
        radius: 6,
        color: img.ColorRgb8(0, 0, 255), // Blue
      );
    }

    // Draw rep count text
    if (repCount != null) {
      img.drawString(
        image,
        'Reps: $repCount',
        font: img.arial48,
        x: 20,
        y: 20,
        color: img.ColorRgb8(255, 255, 255),
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

// Color schemes for different exercise types
class PoseColors {
  static const Color pushUpColor = Colors.green;
  static const Color pullUpColor = Colors.blue;
  static const Color sitUpColor = Colors.orange;

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
      default:
        return Colors.green;
    }
  }
}
