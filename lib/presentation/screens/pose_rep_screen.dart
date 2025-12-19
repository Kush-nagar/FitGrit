/// Main screen for pose estimation and rep counting.
/// Supports both real-time camera mode and video file processing.
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../../models/keypoint.dart';
import '../../models/rep_counter.dart';
import '../../services/camera_service.dart';
import '../../services/video_service.dart';
import '../../services/pose_estimator.dart';
import '../../widgets/pose_painter.dart';

enum AppMode { camera, video, processing, exporting }

class PoseRepScreen extends StatefulWidget {
  const PoseRepScreen({super.key});

  @override
  State<PoseRepScreen> createState() => _PoseRepScreenState();
}

class _PoseRepScreenState extends State<PoseRepScreen> {
  // Services
  final CameraService _cameraService = CameraService();
  final VideoService _videoService = VideoService();
  final PoseEstimator _poseEstimator = PoseEstimator();

  // State
  AppMode _mode = AppMode.camera;
  ExerciseType _selectedExercise = ExerciseType.pushUp;
  RepCounter? _repCounter;

  List<Keypoint> _currentKeypoints = [];
  List<Keypoint> _smoothedKeypoints = [];
  bool _isProcessing = false;

  // Video state
  VideoPlayerController? _videoController;
  String? _currentVideoPath;
  Map<int, List<Keypoint>> _videoFrameKeypoints = {}; // timestamp -> keypoints
  double _exportProgress = 0.0;

  // Camera stream subscription
  StreamSubscription<CameraImage>? _cameraStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _poseEstimator.initialize();
      _repCounter = RepCounter(exerciseType: _selectedExercise);
      setState(() {});
    } catch (e) {
      _showError('Initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _cameraStreamSubscription?.cancel();
    _cameraService.dispose();
    _videoService.dispose();
    _videoController?.dispose();
    _poseEstimator.dispose();
    super.dispose();
  }

  // Camera Mode Functions

  Future<void> _startCamera() async {
    if (_mode == AppMode.video) {
      await _stopVideo();
    }

    try {
      setState(() => _isProcessing = true);

      await _cameraService.initialize();
      final stream = _cameraService.startFrameStream();

      _cameraStreamSubscription = stream.listen(_processFrame);

      setState(() {
        _mode = AppMode.camera;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Camera start failed: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _stopCamera() async {
    await _cameraStreamSubscription?.cancel();
    _cameraStreamSubscription = null;
    await _cameraService.stopFrameStream();
  }

  Future<void> _processFrame(CameraImage frame) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final keypoints = await _poseEstimator.estimatePose(frame);

      // Apply smoothing
      _currentKeypoints = keypoints;
      _smoothedKeypoints = _currentKeypoints.isNotEmpty &&
              _smoothedKeypoints.isNotEmpty
          ? _currentKeypoints // TODO: Apply smoothing via PoseUtils.smoothKeypoints
          : _currentKeypoints;

      // Update rep counter
      if (_repCounter != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _repCounter!.update(_smoothedKeypoints, timestamp);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Video Mode Functions

  Future<void> _pickVideo() async {
    await _stopCamera();

    final videoPath = await _videoService.pickVideo();
    if (videoPath == null) return;

    setState(() {
      _currentVideoPath = videoPath;
      _mode = AppMode.video;
    });

    await _initializeVideoPlayer(videoPath);
  }

  Future<void> _initializeVideoPlayer(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    setState(() {});
  }

  Future<void> _analyzeVideo() async {
    if (_currentVideoPath == null) return;

    setState(() {
      _mode = AppMode.processing;
      _videoFrameKeypoints.clear();
    });

    try {
      // Reset rep counter
      _repCounter?.reset();

      // Extract frames using ffmpeg (more reliable)
      final tempDir = await getTemporaryDirectory();
      final frames = await _videoService.extractFramesWithFFmpeg(
        _currentVideoPath!,
        targetFps: 15,
        outputDir: tempDir.path,
      );

      if (frames.isEmpty) {
        _showError('Frame extraction failed');
        setState(() => _mode = AppMode.video);
        return;
      }

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        final framePath = frames[i];
        final timestamp = (i * (1000 / 15)).round(); // Approximate timestamp

        final videoFrame =
            await _videoService.loadFrameFromDisk(framePath, timestamp);
        if (videoFrame == null) continue;

        // Run pose estimation
        final keypoints = await _poseEstimator.estimateFromBytes(
          videoFrame.rgbBytes,
          videoFrame.width,
          videoFrame.height,
        );

        // Update rep counter
        _repCounter?.update(keypoints, timestamp);

        // Store keypoints for this frame
        _videoFrameKeypoints[timestamp] = keypoints;

        // Update progress
        if (mounted) {
          setState(() {
            _exportProgress = (i + 1) / frames.length;
          });
        }
      }

      // Cleanup extracted frames
      await _videoService
          .cleanupFrameDirectory('${tempDir.path}/video_frames_*');

      setState(() {
        _mode = AppMode.video;
        _exportProgress = 0.0;
      });

      _showSuccess(
          'Video analysis complete! Reps: ${_repCounter?.repCount ?? 0}');
    } catch (e) {
      _showError('Video analysis failed: $e');
      setState(() => _mode = AppMode.video);
    }
  }

  Future<void> _exportAnnotatedVideo() async {
    if (_currentVideoPath == null || _videoFrameKeypoints.isEmpty) {
      _showError('No analyzed video to export');
      return;
    }

    setState(() => _mode = AppMode.exporting);

    try {
      final tempDir = await getTemporaryDirectory();
      final frameDir =
          '${tempDir.path}/annotated_frames_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(frameDir).create(recursive: true);

      // Extract original frames again
      final frames = await _videoService.extractFramesWithFFmpeg(
        _currentVideoPath!,
        targetFps: 15,
        outputDir: tempDir.path,
      );

      // Annotate each frame
      for (int i = 0; i < frames.length; i++) {
        final timestamp = (i * (1000 / 15)).round();
        final keypoints = _videoFrameKeypoints[timestamp] ?? [];
        final repCount = _repCounter?.getRepCountAt(timestamp) ?? 0;

        // Load original frame
        final videoFrame =
            await _videoService.loadFrameFromDisk(frames[i], timestamp);
        if (videoFrame == null) continue;

        // Render annotated frame
        final annotatedBytes = await _renderAnnotatedFrameHelper(
          videoFrame.rgbBytes,
          keypoints,
          videoFrame.width,
          videoFrame.height,
          repCount,
        );

        // Save annotated frame
        await _videoService.saveAnnotatedFrame(
          frameNumber: i + 1,
          imageBytes: annotatedBytes,
          outputDir: frameDir,
        );

        // Update progress
        if (mounted) {
          setState(() {
            _exportProgress = (i + 1) / frames.length;
          });
        }
      }

      // Stitch frames into video using ffmpeg
      final outputPath =
          '${tempDir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final result = await _videoService.exportAnnotatedVideo(
        sourceVideoPath: _currentVideoPath!,
        framesDir: frameDir,
        outputPath: outputPath,
        fps: 15,
        includeAudio: true,
      );

      // Cleanup
      await _videoService.cleanupFrameDirectory(frameDir);

      if (result != null) {
        _showSuccess('Video exported: $result');
        // TODO: Offer to save to gallery or share
      } else {
        _showError('Video export failed');
      }

      setState(() {
        _mode = AppMode.video;
        _exportProgress = 0.0;
      });
    } catch (e) {
      _showError('Export failed: $e');
      setState(() => _mode = AppMode.video);
    }
  }

  Future<void> _stopVideo() async {
    await _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _currentVideoPath = null;
    _videoFrameKeypoints.clear();
  }

  // Helper to render annotated frame (uses image package)
  Future<Uint8List> _renderAnnotatedFrameHelper(
    Uint8List frameRgb,
    List<Keypoint> keypoints,
    int width,
    int height,
    int repCount,
  ) async {
    // TODO: Use PoseUtils.renderAnnotatedFrame when image package is properly integrated
    // For now, return original frame
    // This is a placeholder - actual implementation in pose_utils.dart
    return frameRgb;
  }

  // UI Builders

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pose Rep Counter'),
        actions: [
          // Exercise selector
          DropdownButton<ExerciseType>(
            value: _selectedExercise,
            items: ExerciseType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedExercise = value;
                  _repCounter = RepCounter(exerciseType: value);
                });
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildControls(),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case AppMode.camera:
        return _buildCameraView();
      case AppMode.video:
        return _buildVideoView();
      case AppMode.processing:
        return _buildProcessingView();
      case AppMode.exporting:
        return _buildExportingView();
    }
  }

  Widget _buildCameraView() {
    if (!_cameraService.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: CameraPreview(_cameraService.controller!),
        ),
        // Pose overlay
        Positioned.fill(
          child: PoseOverlay(
            keypoints: _smoothedKeypoints,
            repCount: _repCounter?.repCount,
            exerciseType: _selectedExercise.toString().split('.').last,
          ),
        ),
        // Rep counter display
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Reps: ${_repCounter?.repCount ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoView() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: Text('Pick a video to analyze'),
      );
    }

    return Stack(
      children: [
        // Video player
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        // Play/pause controls
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 64,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
        // Rep count overlay
        if (_videoFrameKeypoints.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reps: ${_repCounter?.repCount ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Analyzing video...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text('${(_exportProgress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(value: _exportProgress),
          ),
        ],
      ),
    );
  }

  Widget _buildExportingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Exporting annotated video...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text('${(_exportProgress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(value: _exportProgress),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera button
          ElevatedButton.icon(
            onPressed: _mode == AppMode.camera ? _stopCamera : _startCamera,
            icon: Icon(_mode == AppMode.camera ? Icons.stop : Icons.camera),
            label: Text(_mode == AppMode.camera ? 'Stop' : 'Camera'),
          ),
          // Video button
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('Pick Video'),
          ),
          // Analyze button (video mode only)
          if (_mode == AppMode.video && _currentVideoPath != null)
            ElevatedButton.icon(
              onPressed: _analyzeVideo,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze'),
            ),
          // Export button (after analysis)
          if (_mode == AppMode.video && _videoFrameKeypoints.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _exportAnnotatedVideo,
              icon: const Icon(Icons.file_download),
              label: const Text('Export'),
            ),
        ],
      ),
    );
  }

  // Helpers

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// TODO: Add permission handling before starting camera/video:
// - Check camera/microphone permissions
// - Show rationale if denied
// - Request permissions if not granted
//
// TODO: Improve video playback synchronization:
// - Listen to video position updates
// - Display nearest analyzed frame's keypoints during playback
// - Add frame-by-frame scrubbing
//
// TODO: Add settings panel:
// - Adjust confidence thresholds
// - Configure rep counter sensitivity
// - Choose export resolution/quality
// - Toggle skeleton/keypoint visibility
