/// On-device MoveNet pose estimation using TFLite.
/// Supports both real-time camera frames and video file frames.
/// API: estimatePose(CameraImage) or estimateFromBytes(Uint8List).
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/keypoint.dart';

class PoseEstimator {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // MoveNet Lightning model input: 192x192x3 (RGB)
  static const int inputSize = 192;
  static const double confidenceThreshold = 0.25;

  /// Initialize the TFLite interpreter.
  /// Call this once before estimating poses.
  /// TODO: Download movenet_single_pose_lightning_int8.tflite from TensorFlow Hub
  /// and place in assets/models/ then update pubspec.yaml assets section.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: Update path to your actual model file
      _interpreter = await Interpreter.fromAsset(
        'assets/models/movenet_single_pose_lightning_int8.tflite',
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true, // Hardware acceleration on Android
      );
      _isInitialized = true;
      print('✓ PoseEstimator initialized');
    } catch (e) {
      print('✗ PoseEstimator initialization failed: $e');
      rethrow;
    }
  }

  /// Estimate pose from a camera frame (real-time).
  Future<List<Keypoint>> estimatePose(CameraImage image) async {
    if (!_isInitialized) {
      throw StateError(
          'PoseEstimator not initialized. Call initialize() first.');
    }

    // Convert CameraImage to RGB bytes
    final rgbBytes = _convertCameraImageToRGB(image);
    return estimateFromBytes(
      rgbBytes,
      image.width,
      image.height,
      rotation: 0,
      mirrored: false,
    );
  }

  /// Estimate pose from raw RGB bytes (for video frames).
  /// [rgbBytes]: RGB888 format (width * height * 3 bytes)
  /// [width], [height]: Frame dimensions
  /// [rotation]: 0, 90, 180, 270 degrees
  /// [mirrored]: Whether to mirror horizontally (for front camera)
  Future<List<Keypoint>> estimateFromBytes(
    Uint8List rgbBytes,
    int width,
    int height, {
    int rotation = 0,
    bool mirrored = false,
  }) async {
    if (!_isInitialized) {
      throw StateError(
          'PoseEstimator not initialized. Call initialize() first.');
    }

    // Preprocess: resize and normalize
    final input =
        await _preprocessImage(rgbBytes, width, height, rotation, mirrored);

    // Run inference
    final output = _createOutputBuffer();
    _interpreter!.run(input, output);

    // Parse keypoints
    return _parseKeypoints(output, mirrored);
  }

  /// Preprocess image: resize to 192x192, normalize to [0, 255] uint8
  Future<Uint8List> _preprocessImage(
    Uint8List rgbBytes,
    int width,
    int height,
    int rotation,
    bool mirrored,
  ) async {
    // Decode image
    var image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      numChannels: 3,
    );

    // Apply rotation if needed
    if (rotation == 90) {
      image = img.copyRotate(image, angle: 90);
    } else if (rotation == 180) {
      image = img.copyRotate(image, angle: 180);
    } else if (rotation == 270) {
      image = img.copyRotate(image, angle: 270);
    }

    // Mirror if front camera
    if (mirrored) {
      image = img.flipHorizontal(image);
    }

    // Resize to model input size (192x192)
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Uint8List (RGB888)
    final buffer = Uint8List(inputSize * inputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r.toInt();
        buffer[pixelIndex++] = pixel.g.toInt();
        buffer[pixelIndex++] = pixel.b.toInt();
      }
    }

    return buffer;
  }

  /// Convert CameraImage (YUV420/NV21) to RGB
  Uint8List _convertCameraImageToRGB(CameraImage image) {
    // TODO: Optimize YUV to RGB conversion for production (use native code or lookup tables)
    // This is a simplified conversion; for better performance, use platform-specific methods

    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToRGB(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToRGB(image);
    } else {
      throw UnsupportedError('Unsupported image format: ${image.format.group}');
    }
  }

  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final Uint8List rgb = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yValue = image.planes[0].bytes[yIndex];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }

    return rgb;
  }

  Uint8List _convertBGRA8888ToRGB(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final rgb = Uint8List(image.width * image.height * 3);

    for (int i = 0, j = 0; i < bytes.length; i += 4, j += 3) {
      rgb[j] = bytes[i + 2]; // R
      rgb[j + 1] = bytes[i + 1]; // G
      rgb[j + 2] = bytes[i]; // B
    }

    return rgb;
  }

  /// Create output buffer for MoveNet (1x1x17x3)
  /// Output format: [batch, 1, 17 keypoints, 3 values (y, x, confidence)]
  List<List<List<List<double>>>> _createOutputBuffer() {
    return List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(
          17,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );
  }

  /// Parse MoveNet output to Keypoint list
  List<Keypoint> _parseKeypoints(
    List<List<List<List<double>>>> output,
    bool mirrored,
  ) {
    final keypoints = <Keypoint>[];
    final rawKeypoints = output[0][0]; // Shape: [17, 3]

    for (int i = 0; i < KeypointNames.all.length; i++) {
      final name = KeypointNames.all[i];
      var x = rawKeypoints[i][1]; // x coordinate (normalized 0-1)
      final y = rawKeypoints[i][0]; // y coordinate (normalized 0-1)
      final confidence = rawKeypoints[i][2];

      // Mirror x-coordinate if needed
      if (mirrored) {
        x = 1.0 - x;
      }

      // Only include keypoints above confidence threshold
      if (confidence >= confidenceThreshold) {
        keypoints.add(Keypoint(
          name: name,
          x: x,
          y: y,
          confidence: confidence,
        ));
      }
    }

    return keypoints;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}

// TODO: For heavy video processing, consider running inference in an isolate:
//
// Future<List<Keypoint>> estimateInIsolate(IsolateParams params) async {
//   return Isolate.run(() async {
//     final estimator = PoseEstimator();
//     await estimator.initialize();
//     final result = await estimator.estimateFromBytes(...);
//     estimator.dispose();
//     return result;
//   });
// }
