/// Real-time camera stream service for pose estimation.
/// Provides camera preview stream and optional video recording.
import 'dart:async';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  StreamController<CameraImage>? _frameStreamController;
  bool _isRecording = false;
  String? _recordingPath;

  /// Initialize camera service
  Future<void> initialize({
    CameraLensDirection direction = CameraLensDirection.front,
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException(
            'NoCamerasAvailable', 'No cameras found on device');
      }

      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: true,
        imageFormatGroup:
            ImageFormatGroup.yuv420, // YUV for Android, BGRA for iOS
      );

      await _controller!.initialize();
      print('✓ CameraService initialized: ${camera.name}');
    } catch (e) {
      print('✗ CameraService initialization failed: $e');
      rethrow;
    }
  }

  /// Start streaming camera frames
  /// Returns a stream of CameraImage for real-time pose estimation
  Stream<CameraImage> startFrameStream() {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('Camera not initialized. Call initialize() first.');
    }

    _frameStreamController?.close();
    _frameStreamController = StreamController<CameraImage>.broadcast();

    _controller!.startImageStream((CameraImage image) {
      _frameStreamController?.add(image);
    });

    print('✓ Frame stream started');
    return _frameStreamController!.stream;
  }

  /// Stop streaming camera frames
  Future<void> stopFrameStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
      await _frameStreamController?.close();
      _frameStreamController = null;
      print('✓ Frame stream stopped');
    }
  }

  /// Start video recording
  /// Returns path where video will be saved
  Future<String> startRecording(String outputPath) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('Camera not initialized. Call initialize() first.');
    }

    if (_controller!.value.isStreamingImages) {
      await stopFrameStream();
    }

    await _controller!.startVideoRecording();
    _isRecording = true;
    _recordingPath = outputPath;
    print('✓ Recording started: $outputPath');
    return outputPath;
  }

  /// Stop video recording
  /// Returns path to recorded video file
  Future<String> stopRecording() async {
    if (_controller == null || !_isRecording) {
      throw StateError('No recording in progress');
    }

    final file = await _controller!.stopVideoRecording();
    _isRecording = false;
    print('✓ Recording stopped: ${file.path}');
    return file.path;
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      print('✗ Cannot switch camera: only one camera available');
      return;
    }

    final wasStreaming = _controller?.value.isStreamingImages ?? false;
    if (wasStreaming) {
      await stopFrameStream();
    }

    final currentDirection = _controller?.description.lensDirection;
    final newDirection = currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    await dispose();
    await initialize(direction: newDirection);

    if (wasStreaming) {
      startFrameStream();
    }

    print('✓ Switched to $newDirection camera');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopFrameStream();
    await _controller?.dispose();
    _controller = null;
    _isRecording = false;
    _recordingPath = null;
  }

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;
  CameraLensDirection? get currentDirection =>
      _controller?.description.lensDirection;
}

// TODO: Add helpers for camera permission checking:
//
// Future<bool> checkCameraPermission() async {
//   final status = await Permission.camera.status;
//   if (status.isDenied) {
//     final result = await Permission.camera.request();
//     return result.isGranted;
//   }
//   return status.isGranted;
// }
//
// Future<bool> checkMicrophonePermission() async {
//   final status = await Permission.microphone.status;
//   if (status.isDenied) {
//     final result = await Permission.microphone.request();
//     return result.isGranted;
//   }
//   return status.isGranted;
// }
