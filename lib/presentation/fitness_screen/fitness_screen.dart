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
        title: 'Fitness Tracker',
        centerTitle: false,
        actions: [
          // Modern exercise selector with card design
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<ExerciseType>(
              value: _selectedExercise,
              dropdownColor: theme.colorScheme.surfaceContainerHighest,
              underline: const SizedBox(),
              icon: Icon(Icons.fitness_center,
                  color: theme.colorScheme.primary, size: 18),
              items: ExerciseType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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
          ),
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
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Start',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap "Start Camera" below to begin tracking',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox.expand(
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(0)),
            child: CameraPreview(_cameraService.controller!),
          ),
        ),
        Positioned.fill(
          child: PoseOverlay(
            keypoints: _smoothedKeypoints,
            repCount: _repCounter?.repCount,
            exerciseType: _selectedExercise.toString().split('.').last,
          ),
        ),
        // Modern rep counter display
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .shadow
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'REPS: ${_repCounter?.repCount ?? 0}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoView() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Video Selected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pick a video to analyze your workout',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: VideoPlayer(_videoController!),
            ),
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
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_videoFrameKeypoints.isNotEmpty)
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.95),
                    Theme.of(context)
                        .colorScheme
                        .tertiaryContainer
                        .withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: Theme.of(context).colorScheme.onTertiary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'REPS: ${_repCounter?.repCount ?? 0}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Analyzing Video',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_exportProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 12,
                child: LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing frames and detecting movements...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportingView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_file_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Exporting Video',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_exportProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 12,
                child: LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Creating annotated video with rep counts...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera button - Modern design
            _buildModernButton(
              icon: _mode == AppMode.camera
                  ? Icons.stop_rounded
                  : Icons.videocam_rounded,
              label: _mode == AppMode.camera ? 'Stop' : 'Camera',
              onPressed: _mode == AppMode.camera ? _stopCamera : _startCamera,
              isPrimary: _mode == AppMode.camera,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            // Video button - Modern design
            _buildModernButton(
              icon: Icons.video_library_rounded,
              label: 'Video',
              onPressed: _pickVideo,
              isPrimary: false,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            if (_mode == AppMode.video && _currentVideoPath != null) ...[
              const SizedBox(width: 12),
              // Analyze button - Modern design
              _buildModernButton(
                icon: Icons.analytics_rounded,
                label: 'Analyze',
                onPressed: _analyzeVideo,
                isPrimary: true,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
            if (_mode == AppMode.video && _videoFrameKeypoints.isNotEmpty) ...[
              const SizedBox(width: 12),
              // Export button - Modern design
              _buildModernButton(
                icon: Icons.file_download_rounded,
                label: 'Export',
                onPressed: _exportAnnotatedVideo,
                isPrimary: false,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: isPrimary ? null : color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isPrimary ? 0 : 0.3),
              width: isPrimary ? 0 : 2,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isPrimary ? Theme.of(context).colorScheme.onPrimary : color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Theme.of(context).colorScheme.onPrimary
                      : color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
