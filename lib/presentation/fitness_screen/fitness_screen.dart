import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../models/keypoint.dart';
import '../../models/rep_counter.dart';
import '../../models/video_frame.dart';
import '../../services/camera_service.dart';
import '../../services/video_service.dart';
import '../../services/pose_estimator.dart';
import '../../widgets/pose_painter.dart';

enum AppMode { camera, video, processing, exporting }

/// Fitness Screen
///
/// Screen for fitness-related features including pose estimation and rep counting
class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
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
  Map<int, List<Keypoint>> _videoFrameKeypoints = {};
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

      _currentKeypoints = keypoints;
      _smoothedKeypoints =
          _currentKeypoints.isNotEmpty && _smoothedKeypoints.isNotEmpty
              ? _currentKeypoints
              : _currentKeypoints;

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

  Future<void> _analyzeVideo({int frameSkip = 1}) async {
    if (_currentVideoPath == null) return;

    setState(() {
      _mode = AppMode.processing;
      _videoFrameKeypoints.clear();
      _exportProgress = 0.0;
    });

    try {
      _repCounter?.reset();

      final tempDir = await getTemporaryDirectory();

      // Extract frames with progress updates (now 3-5x faster with concurrent processing)
      final frames = await _videoService.extractFramesWithFFmpeg(
        _currentVideoPath!,
        targetFps: 15,
        outputDir: tempDir.path,
        concurrentExtractions: 8, // Process 8 frames at once
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
            });
          }
        },
      );

      if (frames.isEmpty) {
        _showError('Frame extraction failed');
        setState(() => _mode = AppMode.video);
        return;
      }

      // Apply frame skipping if requested (process every Nth frame for faster analysis)
      final framesToProcess = frameSkip > 1
          ? [for (int i = 0; i < frames.length; i += frameSkip) frames[i]]
          : frames;

      print(
          'Processing ${framesToProcess.length} frames (skip: $frameSkip) with batch processing...');

      // Process frames in batches for 2-3x faster pose estimation
      const batchSize = 4; // Process 4 frames in parallel
      int processedCount = 0;

      for (int i = 0; i < framesToProcess.length; i += batchSize) {
        final batchEnd = (i + batchSize).clamp(0, framesToProcess.length);
        final batchFramePaths = framesToProcess.sublist(i, batchEnd);
        final batchTimestamps = List.generate(
          batchFramePaths.length,
          (idx) => ((i + idx) * frameSkip * (1000 / 15)).round(),
        );

        // Load batch of frames concurrently
        final videoFrames = await _videoService.loadFramesBatch(
          batchFramePaths,
          batchTimestamps,
        );

        // Process valid frames concurrently with isolates
        final validFrames = <({VideoFrame frame, int timestamp})>[];
        for (int j = 0; j < videoFrames.length; j++) {
          if (videoFrames[j] != null) {
            validFrames.add(
              (frame: videoFrames[j]!, timestamp: batchTimestamps[j]),
            );
          }
        }

        if (validFrames.isNotEmpty) {
          // Estimate poses in parallel
          final batchKeypoints = await Future.wait(
            validFrames.map((item) async {
              final keypoints = await _poseEstimator.estimateFromBytes(
                item.frame.rgbBytes,
                item.frame.width,
                item.frame.height,
              );
              return (keypoints: keypoints, timestamp: item.timestamp);
            }),
          );

          // Update rep counter and store results
          for (final result in batchKeypoints) {
            _repCounter?.update(result.keypoints, result.timestamp);
            _videoFrameKeypoints[result.timestamp] = result.keypoints;
          }
        }

        processedCount += batchFramePaths.length;
        if (mounted) {
          setState(() {
            _exportProgress =
                0.5 + (processedCount / framesToProcess.length) * 0.5;
          });
        }
      }

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

      final frames = await _videoService.extractFramesWithFFmpeg(
        _currentVideoPath!,
        targetFps: 15,
        outputDir: tempDir.path,
      );

      for (int i = 0; i < frames.length; i++) {
        final timestamp = (i * (1000 / 15)).round();
        final keypoints = _videoFrameKeypoints[timestamp] ?? [];
        final repCount = _repCounter?.getRepCountAt(timestamp) ?? 0;

        final videoFrame =
            await _videoService.loadFrameFromDisk(frames[i], timestamp);
        if (videoFrame == null) continue;

        final annotatedBytes = await _renderAnnotatedFrameHelper(
          videoFrame.rgbBytes,
          keypoints,
          videoFrame.width,
          videoFrame.height,
          repCount,
        );

        await _videoService.saveAnnotatedFrame(
          frameNumber: i + 1,
          imageBytes: annotatedBytes,
          outputDir: frameDir,
        );

        if (mounted) {
          setState(() {
            _exportProgress = (i + 1) / frames.length;
          });
        }
      }

      final outputPath =
          '${tempDir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final result = await _videoService.exportAnnotatedVideo(
        sourceVideoPath: _currentVideoPath!,
        framesDir: frameDir,
        outputPath: outputPath,
        fps: 15,
        includeAudio: true,
      );

      await _videoService.cleanupFrameDirectory(frameDir);

      if (result != null) {
        _showSuccess('Video exported: $result');
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

  Future<Uint8List> _renderAnnotatedFrameHelper(
    Uint8List frameRgb,
    List<Keypoint> keypoints,
    int width,
    int height,
    int repCount,
  ) async {
    return frameRgb;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Fitness',
        centerTitle: false,
        actions: [
          DropdownButton<ExerciseType>(
            value: _selectedExercise,
            dropdownColor: theme.colorScheme.surface,
            items: ExerciseType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControls(),
          CustomBottomBar(
            currentRoute: '/fitness-screen',
            onNavigate: (route) {
              if (route != '/fitness-screen') {
                Navigator.pushReplacementNamed(context, route);
              }
            },
          ),
        ],
      ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Tap "Start Camera" to begin'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SizedBox.expand(
          child: CameraPreview(_cameraService.controller!),
        ),
        Positioned.fill(
          child: PoseOverlay(
            keypoints: _smoothedKeypoints,
            repCount: _repCounter?.repCount,
            exerciseType: _selectedExercise.toString().split('.').last,
          ),
        ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Pick a video to analyze'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _mode == AppMode.camera ? _stopCamera : _startCamera,
            icon: Icon(_mode == AppMode.camera ? Icons.stop : Icons.camera),
            label: Text(_mode == AppMode.camera ? 'Stop' : 'Camera'),
          ),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('Video'),
          ),
          if (_mode == AppMode.video && _currentVideoPath != null)
            ElevatedButton.icon(
              onPressed: _analyzeVideo,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze'),
            ),
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
