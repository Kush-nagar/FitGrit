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
import '../../models/flexibility_form_analyzer.dart';
import '../../models/shuttle_run_analyzer.dart';
import '../../services/camera_service.dart';
import '../../services/video_service.dart';
import '../../services/pose_estimator.dart';
import '../../services/flexibility_metrics_calculator.dart';
import '../../services/shuttle_run_metrics_calculator.dart';
import '../../services/firebase_fitness_service.dart';
import '../../services/presidential_fitness_benchmarks.dart';
import '../../services/user_preferences_service.dart';
import '../../widgets/pose_painter.dart';
import '../shuttle_run_details_screen/shuttle_run_details_screen.dart';

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
  final FirebaseFitnessService _firebaseFitnessService =
      FirebaseFitnessService();
  final UserPreferencesService _userPrefsService = UserPreferencesService();

  // User data for benchmarks
  int? _userAge;
  Gender? _userGender;

  // State
  AppMode _mode = AppMode.camera;
  ExerciseType _selectedExercise = ExerciseType.pushUp;
  RepCounter? _repCounter;
  bool _showWorkoutSelection = true;

  // Flexibility analysis state
  FlexibilityFormAnalyzer? _flexibilityAnalyzer;
  FlexibilityMetricsCalculator? _flexibilityCalculator;
  FlexibilityFormMetrics? _currentFlexibilityForm;
  FlexibilityMetrics? _currentFlexibilityMetrics;
  FlexibilityTestType _selectedFlexibilityTest =
      FlexibilityTestType.sitAndReach;
  double _participantHeight = 1.75; // meters
  bool _baselineSet = false;

  // Rep counter for flexibility exercises
  RepCounter? _flexibilityRepCounter;
  int _flexibilityRepCount = 0;

  // Shuttle run analysis state
  ShuttleRunAnalyzer? _shuttleRunAnalyzer;
  ShuttleRunMetricsCalculator? _shuttleRunCalculator;
  ShuttleRunMetrics? _currentShuttleRunForm;
  ShuttleRunPerformanceMetrics? _currentShuttleRunMetrics;
  final double _shuttleDistance = 20.0; // meters (20m is standard)

  List<Keypoint> _currentKeypoints = [];
  List<Keypoint> _smoothedKeypoints = [];
  bool _isProcessing = false;

  // Video state
  VideoPlayerController? _videoController;
  String? _currentVideoPath;
  final Map<int, List<Keypoint>> _videoFrameKeypoints = {};
  double _exportProgress = 0.0;

  // Camera stream subscription
  StreamSubscription<CameraImage>? _cameraStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userAge = await _userPrefsService.getAge();
    _userGender = await _userPrefsService.getGender();
    setState(() {});
  }

  Future<void> _initializeServices() async {
    try {
      await _poseEstimator.initialize();
      _repCounter = RepCounter(exerciseType: _selectedExercise);
      _flexibilityAnalyzer = FlexibilityFormAnalyzer(
        testType: _selectedFlexibilityTest,
      );
      _flexibilityCalculator = FlexibilityMetricsCalculator(
        testType: _selectedFlexibilityTest,
        participantHeight: _participantHeight,
      );
      // Initialize rep counter for flexibility exercises
      _flexibilityRepCounter = RepCounter(
        exerciseType:
            _selectedFlexibilityTest == FlexibilityTestType.sitAndReach
                ? ExerciseType.sitAndReach
                : ExerciseType.vSitAndReach,
        upThreshold: 0.7,
        downThreshold: 0.3,
      );
      // Initialize shuttle run analyzers
      _shuttleRunAnalyzer = ShuttleRunAnalyzer();
      _shuttleRunCalculator = ShuttleRunMetricsCalculator(
        shuttleDistance: _shuttleDistance,
        videoFps: 30.0,
      );
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

  // Clear video analysis state
  void _clearVideoAnalysisState() {
    _videoController?.dispose();
    _videoController = null;
    _currentVideoPath = null;
    _videoFrameKeypoints.clear();
    _exportProgress = 0.0;
    _currentKeypoints = [];
    _smoothedKeypoints = [];
    _mode = AppMode.camera;

    // Reset rep counters
    _repCounter?.reset();
    _flexibilityRepCounter?.reset();
    _flexibilityAnalyzer?.reset();
    _flexibilityCalculator?.reset();
    _baselineSet = false;
    _flexibilityRepCount = 0;
    _currentFlexibilityForm = null;
    _currentFlexibilityMetrics = null;
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

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Update rep counter or flexibility analyzer based on exercise type
      if (_selectedExercise == ExerciseType.running) {
        // Running pose estimation removed - keep section empty
      } else if (_selectedExercise == ExerciseType.shuttleRun) {
        // Handle shuttle run
        if (_shuttleRunAnalyzer != null) {
          _currentShuttleRunForm =
              _shuttleRunAnalyzer!.analyzeFrame(_smoothedKeypoints, timestamp);
        }
        if (_shuttleRunCalculator != null) {
          _shuttleRunCalculator!.addFrame(_smoothedKeypoints);
          _currentShuttleRunMetrics = _shuttleRunCalculator!.calculateMetrics();
        }
      } else if (_selectedExercise == ExerciseType.sitAndReach ||
          _selectedExercise == ExerciseType.vSitAndReach) {
        // Handle flexibility exercises
        if (!_baselineSet) {
          // Set baseline on first valid frame
          if (_flexibilityCalculator != null) {
            _flexibilityCalculator!.setBaseline(_smoothedKeypoints);
            _baselineSet = true;
          }
        }

        // Update rep counter for flexibility exercises
        if (_flexibilityRepCounter != null) {
          _flexibilityRepCounter!.update(_smoothedKeypoints, timestamp);
          _flexibilityRepCount = _flexibilityRepCounter!.repCount;
        }

        if (_flexibilityAnalyzer != null) {
          _currentFlexibilityForm =
              _flexibilityAnalyzer!.analyzeFrame(_smoothedKeypoints, timestamp);
        }
        if (_flexibilityCalculator != null) {
          _flexibilityCalculator!.addFrame(_smoothedKeypoints);
          _currentFlexibilityMetrics =
              _flexibilityCalculator!.calculateMetrics();
        }
      } else {
        if (_repCounter != null) {
          _repCounter!.update(_smoothedKeypoints, timestamp);
        }
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
      _flexibilityRepCounter?.reset();
      _flexibilityAnalyzer?.reset();
      _flexibilityCalculator?.reset();
      _baselineSet = false;

      final tempDir = await getTemporaryDirectory();

      // Optimize frame skip for shuttle run (can analyze fewer frames)
      final effectiveFrameSkip = _selectedExercise == ExerciseType.shuttleRun
          ? 2 // Skip every other frame for shuttle run (30% faster)
          : frameSkip;

      // Extract frames with progress updates (optimized for speed)
      final frames = await _videoService.extractFramesWithFFmpeg(
        _currentVideoPath!,
        targetFps: 15,
        outputDir: tempDir.path,
        concurrentExtractions:
            8, // Balanced extraction speed (was 12, reduced for stability)
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
      final framesToProcess = effectiveFrameSkip > 1
          ? [
              for (int i = 0; i < frames.length; i += effectiveFrameSkip)
                frames[i]
            ]
          : frames;

      print(
          'Processing ${framesToProcess.length} frames (skip: $effectiveFrameSkip) with batch processing...');

      // Process frames in batches for faster pose estimation
      // Reduced batch size to prevent memory issues on mobile devices
      final batchSize = _selectedExercise == ExerciseType.shuttleRun
          ? 4 // Moderate batch size for shuttle run (balanced speed/stability)
          : 4; // Standard batch size for rep counting
      int processedCount = 0;

      for (int i = 0; i < framesToProcess.length; i += batchSize) {
        // Add try-catch for each batch to prevent one bad frame from stopping everything
        try {
          final batchEnd = (i + batchSize).clamp(0, framesToProcess.length);
          final batchFramePaths = framesToProcess.sublist(i, batchEnd);
          final batchTimestamps = List.generate(
            batchFramePaths.length,
            (idx) => ((i + idx) * effectiveFrameSkip * (1000 / 15)).round(),
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

            // Update rep counter or flexibility analyzer and store results
            for (final result in batchKeypoints) {
              if (_selectedExercise == ExerciseType.running) {
                // Running pose estimation removed - keep section empty
              } else if (_selectedExercise == ExerciseType.shuttleRun) {
                // Shuttle run analysis
                if (_shuttleRunAnalyzer != null) {
                  _currentShuttleRunForm = _shuttleRunAnalyzer!
                      .analyzeFrame(result.keypoints, result.timestamp);
                }
                if (_shuttleRunCalculator != null) {
                  _shuttleRunCalculator!.addFrame(result.keypoints);
                }
              } else if (_selectedExercise == ExerciseType.sitAndReach ||
                  _selectedExercise == ExerciseType.vSitAndReach) {
                // Flexibility analysis
                if (!_baselineSet && result.keypoints.isNotEmpty) {
                  // Set baseline on first valid frame
                  if (_flexibilityCalculator != null) {
                    _flexibilityCalculator!.setBaseline(result.keypoints);
                    _baselineSet = true;
                  }
                }

                // Update rep counter for flexibility exercises
                if (_flexibilityRepCounter != null) {
                  _flexibilityRepCounter!
                      .update(result.keypoints, result.timestamp);
                  _flexibilityRepCount = _flexibilityRepCounter!.repCount;
                }

                // Update flexibility form analyzer
                if (_flexibilityAnalyzer != null) {
                  _currentFlexibilityForm = _flexibilityAnalyzer!
                      .analyzeFrame(result.keypoints, result.timestamp);
                }

                // Update flexibility metrics calculator
                if (_flexibilityCalculator != null) {
                  _flexibilityCalculator!.addFrame(result.keypoints);
                }
              } else {
                // Standard rep counting
                _repCounter?.update(result.keypoints, result.timestamp);
              }

              // Store keypoints for export
              _videoFrameKeypoints[result.timestamp] = result.keypoints;
            }
          }

          processedCount += batchFramePaths.length;
          if (mounted) {
            setState(() {
              _exportProgress = (processedCount / framesToProcess.length) * 0.5;
            });
          }
        } catch (batchError) {
          print('Error processing batch at index $i: $batchError');
          // Continue with next batch instead of failing completely
          processedCount += batchSize;
        }
      }

      await _videoService
          .cleanupFrameDirectory('${tempDir.path}/video_frames_*');

      // Calculate final metrics for flexibility exercises
      if ((_selectedExercise == ExerciseType.sitAndReach ||
              _selectedExercise == ExerciseType.vSitAndReach) &&
          _flexibilityCalculator != null) {
        _currentFlexibilityMetrics = _flexibilityCalculator!.calculateMetrics();
      }

      // Calculate final metrics for shuttle run
      if (_selectedExercise == ExerciseType.shuttleRun &&
          _shuttleRunCalculator != null) {
        _currentShuttleRunMetrics = _shuttleRunCalculator!.calculateMetrics();
      }

      setState(() {
        _mode = AppMode.video;
        _exportProgress = 0.0;
      });

      if (_selectedExercise == ExerciseType.running) {
        // Running pose estimation removed - keep section empty
      } else if (_selectedExercise == ExerciseType.shuttleRun) {
        // Save shuttle run data to Firebase with benchmark comparison
        if (_currentShuttleRunMetrics != null) {
          await _firebaseFitnessService.saveShuttleRun(
            metrics: _currentShuttleRunMetrics!,
            videoPath: _currentVideoPath,
            userAge: _userAge,
            userGender: _userGender,
          );

          // Calculate benchmark comparison for display
          BenchmarkComparison? comparison;
          if (_userAge != null && _userGender != null) {
            comparison = PresidentialFitnessBenchmarks.compareShuttleRun(
              timeInSeconds: _currentShuttleRunMetrics!.totalTime,
              age: _userAge!,
              gender: _userGender!,
            );
          }

          // Navigate to shuttle run details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShuttleRunDetailsScreen(
                metrics: _currentShuttleRunMetrics!,
                benchmarkComparison: comparison,
              ),
            ),
          );
        } else {
          _showError('No shuttle run metrics available');
        }
      } else if (_selectedExercise == ExerciseType.sitAndReach ||
          _selectedExercise == ExerciseType.vSitAndReach) {
        // Save flexibility test data to Firebase with benchmark comparison
        if (_currentFlexibilityMetrics != null) {
          await _firebaseFitnessService.saveFlexibilityTest(
            metrics: _currentFlexibilityMetrics!,
            reps: _flexibilityRepCount,
            videoPath: _currentVideoPath,
            userAge: _userAge,
            userGender: _userGender,
          );
        }

        // Calculate benchmark comparison for display
        BenchmarkComparison? comparison;
        if (_userAge != null &&
            _userGender != null &&
            _currentFlexibilityMetrics != null) {
          final reachInches = PresidentialFitnessBenchmarks.cmToInches(
            _currentFlexibilityMetrics!.maxReachDistance,
          );
          comparison = PresidentialFitnessBenchmarks.compareFlexibility(
            reachInches: reachInches,
            age: _userAge!,
            gender: _userGender!,
          );
        }

        // Show flexibility-specific results
        final formQuality = _currentFlexibilityForm?.overallQuality
                .toString()
                .split('.')
                .last ??
            'Unknown';
        final maxReach =
            _currentFlexibilityMetrics?.maxReachDistance.toStringAsFixed(1) ??
                '0';
        final score =
            _currentFlexibilityMetrics?.flexibilityScore.toStringAsFixed(0) ??
                '0';

        _showFlexibilityResults(
          formQuality: formQuality,
          maxReach: maxReach,
          score: score,
          reps: _flexibilityRepCount,
          benchmarkComparison: comparison,
        );
      } else {
        // Save rep-based exercise data to Firebase (pushUp, pullUp, sitUp)
        final repCount = _repCounter?.repCount ?? 0;
        if (repCount > 0) {
          await _firebaseFitnessService.saveRepExercise(
            exerciseType: _selectedExercise,
            reps: repCount,
            videoPath: _currentVideoPath,
            userAge: _userAge,
            userGender: _userGender,
          );
        }

        // Calculate benchmark comparison for display
        BenchmarkComparison? comparison;
        if (_userAge != null && _userGender != null && repCount > 0) {
          if (_selectedExercise == ExerciseType.sitUp) {
            comparison = PresidentialFitnessBenchmarks.compareSitUps(
              reps: repCount,
              age: _userAge!,
              gender: _userGender!,
            );
          } else if (_selectedExercise == ExerciseType.pullUp) {
            comparison = PresidentialFitnessBenchmarks.comparePullUps(
              reps: repCount,
              age: _userAge!,
              gender: _userGender!,
            );
          }
        }

        // Show success message (benchmark info now shown inline)
        if (_userAge == null || _userGender == null) {
          _showSuccess(
              'Video analysis complete! Reps: $repCount\n\n💡 Tip: Tap the ⚙️ icon on workout selection to enable Presidential Fitness Test benchmarks!');
        } else {
          _showSuccess('Video analysis complete! Reps: $repCount');
        }
      }
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Presidential Fitness Test Assessment',
        centerTitle: false,
        leading: _showWorkoutSelection
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                onPressed: () {
                  setState(() {
                    _showWorkoutSelection = true;
                    // Stop camera if it's running
                    if (_cameraService.isInitialized) {
                      _stopCamera();
                    }
                    // Clear video analysis state
                    _clearVideoAnalysisState();
                  });
                },
                tooltip: 'Back to workout selection',
              ),
        actions: [
          // Only show actions when not on workout selection screen
          if (!_showWorkoutSelection) ...[
            // Modern exercise selector with card design
            Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
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
                      if (value == ExerciseType.running) {
                        // Running pose estimation removed - keep section empty
                      } else if (value == ExerciseType.sitAndReach ||
                          value == ExerciseType.vSitAndReach) {
                        _selectedFlexibilityTest =
                            value == ExerciseType.sitAndReach
                                ? FlexibilityTestType.sitAndReach
                                : FlexibilityTestType.vSitAndReach;
                        _flexibilityAnalyzer = FlexibilityFormAnalyzer(
                          testType: _selectedFlexibilityTest,
                        );
                        _flexibilityCalculator = FlexibilityMetricsCalculator(
                          testType: _selectedFlexibilityTest,
                          participantHeight: _participantHeight,
                        );
                        _currentFlexibilityForm = null;
                        _currentFlexibilityMetrics = null;
                        _baselineSet = false;
                      } else {
                        _repCounter = RepCounter(exerciseType: value);
                      }
                    });
                  }
                },
              ),
            ),
            // Flexibility settings button (only show when flexibility test is selected)
            if (_selectedExercise == ExerciseType.sitAndReach ||
                _selectedExercise == ExerciseType.vSitAndReach)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(Icons.settings, color: theme.colorScheme.primary),
                  onPressed: _showFlexibilitySettings,
                  tooltip: 'Flexibility Settings',
                ),
              ),
            // Running history button (only show when running is selected)
            if (_selectedExercise == ExerciseType.running)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(Icons.history, color: theme.colorScheme.primary),
                  onPressed: () {
                    Navigator.pushNamed(context, '/running-history-screen');
                  },
                  tooltip: 'Running',
                ),
              ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only show controls when not on workout selection screen
          if (!_showWorkoutSelection) _buildControls(),
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
    // Show workout selection screen first
    if (_showWorkoutSelection) {
      return _buildWorkoutSelectionView();
    }

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

  Widget _buildWorkoutSelectionView() {
    final theme = Theme.of(context);

    // Define workout types with their details using modern, vibrant colors
    final workouts = [
      {
        'type': ExerciseType.pushUp,
        'name': 'Push Ups',
        'icon': Icons.workspaces_rounded,
        'description': 'Track your push-up reps',
        'color': const Color(0xFF3B82F6), // Vibrant blue
      },
      {
        'type': ExerciseType.pullUp,
        'name': 'Pull Ups',
        'icon': Icons.fitness_center_rounded,
        'description': 'Track your pull-up reps',
        'color': const Color(0xFF10B981), // Emerald green
      },
      {
        'type': ExerciseType.sitUp,
        'name': 'Sit Ups',
        'icon': Icons.airline_seat_recline_normal_rounded,
        'description': 'Track your sit-up reps',
        'color': const Color(0xFFF59E0B), // Amber orange
      },
      {
        'type': ExerciseType.running,
        'name': 'Running',
        'icon': Icons.directions_run_rounded,
        'description': 'Analyze your running form',
        'color': const Color(0xFFEF4444), // Vibrant red
      },
      {
        'type': ExerciseType.shuttleRun,
        'name': 'Shuttle Run',
        'icon': Icons.swap_horiz_rounded,
        'description': 'Test your speed and agility',
        'color': const Color(0xFFEC4899), // Pink
      },
      {
        'type': ExerciseType.vSitAndReach,
        'name': 'V-Sit & Reach',
        'icon': Icons.self_improvement_rounded,
        'description': 'Advanced flexibility test',
        'color': const Color(0xFF14B8A6), // Teal
      },
    ];

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                              theme.colorScheme.tertiary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Your Workout',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select an exercise to start tracking',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Settings button for Presidential Fitness Test config
                      IconButton(
                        icon: Icon(
                          Icons.settings_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'Configure Presidential Fitness Test',
                        onPressed: _showConfigureProfileDialog,
                      ),
                    ],
                  ),
                  // Show age/gender status if configured
                  if (_userAge != null && _userGender != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Presidential Fitness Test: Age $_userAge, ${_userGender == Gender.male ? 'Male' : 'Female'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Workout tiles grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.80,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return _buildWorkoutTile(
                    exerciseType: workout['type'] as ExerciseType,
                    name: workout['name'] as String,
                    icon: workout['icon'] as IconData,
                    description: workout['description'] as String,
                    color: workout['color'] as Color,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTile({
    required ExerciseType exerciseType,
    required String name,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Special handling for running - navigate directly to history
            if (exerciseType == ExerciseType.running) {
              Navigator.pushNamed(context, '/running-history-screen');
              return;
            }

            setState(() {
              // Clear any previous video analysis state
              _clearVideoAnalysisState();

              _selectedExercise = exerciseType;
              _showWorkoutSelection = false;

              // Initialize appropriate counter/analyzer based on exercise type
              if (exerciseType == ExerciseType.sitAndReach ||
                  exerciseType == ExerciseType.vSitAndReach) {
                _selectedFlexibilityTest =
                    exerciseType == ExerciseType.sitAndReach
                        ? FlexibilityTestType.sitAndReach
                        : FlexibilityTestType.vSitAndReach;
                _flexibilityAnalyzer = FlexibilityFormAnalyzer(
                  testType: _selectedFlexibilityTest,
                );
                _flexibilityCalculator = FlexibilityMetricsCalculator(
                  testType: _selectedFlexibilityTest,
                  participantHeight: _participantHeight,
                );
                _currentFlexibilityForm = null;
                _currentFlexibilityMetrics = null;
                _baselineSet = false;
              } else if (exerciseType == ExerciseType.shuttleRun) {
                _shuttleRunAnalyzer = ShuttleRunAnalyzer();
                _shuttleRunCalculator = ShuttleRunMetricsCalculator(
                  shuttleDistance: _shuttleDistance,
                  videoFps: 30.0,
                );
                _currentShuttleRunForm = null;
                _currentShuttleRunMetrics = null;
              } else {
                _repCounter = RepCounter(exerciseType: exerciseType);
              }
            });
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withValues(alpha: 0.3),
          highlightColor: color.withValues(alpha: 0.2),
          child: Ink(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container with gradient and glow effect
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Workout name
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Description with subtle styling
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Start indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
            repCount: _selectedExercise == ExerciseType.running ||
                    _selectedExercise == ExerciseType.shuttleRun ||
                    _selectedExercise == ExerciseType.sitAndReach ||
                    _selectedExercise == ExerciseType.vSitAndReach
                ? null
                : _repCounter?.repCount,
            exerciseType: _selectedExercise.toString().split('.').last,
          ),
        ),
        // Shuttle run metrics overlay
        if (_selectedExercise == ExerciseType.shuttleRun &&
            _currentShuttleRunMetrics != null)
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: 0.95),
                    const Color(0xFFF472B6).withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Shuttle Run',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getQualityColor(
                                  _currentShuttleRunForm?.overallQuality)
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getQualityColor(
                                    _currentShuttleRunForm?.overallQuality)
                                .withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _currentShuttleRunForm?.overallQuality
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase() ??
                              'ANALYZING',
                          style: TextStyle(
                            color: _getQualityColor(
                                _currentShuttleRunForm?.overallQuality),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildShuttleMetric(
                        Icons.speed,
                        'Speed',
                        '${_currentShuttleRunMetrics!.averageSpeed.toStringAsFixed(1)} m/s',
                      ),
                      _buildShuttleMetric(
                        Icons.swap_horiz,
                        'Turns',
                        '${_currentShuttleRunMetrics!.directionChanges}',
                      ),
                      _buildShuttleMetric(
                        Icons.fast_forward,
                        'Max',
                        '${_currentShuttleRunMetrics!.maxSpeed.toStringAsFixed(1)} m/s',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        // Modern rep counter display for other exercises
        if (_selectedExercise != ExerciseType.running &&
            _selectedExercise != ExerciseType.shuttleRun &&
            _selectedExercise != ExerciseType.sitAndReach &&
            _selectedExercise != ExerciseType.vSitAndReach)
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
                        .primary
                        .withValues(alpha: 0.95),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                  // Benchmark comparison
                  if (_userAge != null && _userGender != null)
                    ..._buildBenchmarkInfo(),
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
        // Rep counter overlay for standard exercises
        if (_videoFrameKeypoints.isNotEmpty &&
            _selectedExercise != ExerciseType.running &&
            _selectedExercise != ExerciseType.sitAndReach &&
            _selectedExercise != ExerciseType.vSitAndReach)
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                  // Benchmark comparison
                  if (_userAge != null && _userGender != null)
                    ..._buildBenchmarkInfo(isVideoView: true),
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

  /// Show running settings dialog
  void _showFlexibilitySettings() {
    showDialog(
      context: context,
      builder: (context) {
        FlexibilityTestType tempTestType = _selectedFlexibilityTest;
        double tempHeight = _participantHeight;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Flexibility Test Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test type selector
                  const Text('Test Type:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<FlexibilityTestType>(
                    value: tempTestType,
                    isExpanded: true,
                    items: FlexibilityTestType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == FlexibilityTestType.sitAndReach
                              ? 'Sit and Reach'
                              : 'V Sit and Reach',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tempTestType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Participant height slider
                  const Text('Participant Height:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${tempHeight.toStringAsFixed(2)} meters'),
                  Slider(
                    value: tempHeight,
                    min: 1.4,
                    max: 2.1,
                    divisions: 70,
                    label: '${tempHeight.toStringAsFixed(2)}m',
                    onChanged: (value) {
                      setDialogState(() => tempHeight = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFlexibilityTest = tempTestType;
                      _participantHeight = tempHeight;
                      _flexibilityAnalyzer = FlexibilityFormAnalyzer(
                        testType: _selectedFlexibilityTest,
                      );
                      _flexibilityCalculator = FlexibilityMetricsCalculator(
                        testType: _selectedFlexibilityTest,
                        participantHeight: _participantHeight,
                      );
                      _baselineSet = false;
                      _currentFlexibilityForm = null;
                      _currentFlexibilityMetrics = null;

                      // Update exercise type to match selected test
                      _selectedExercise = _selectedFlexibilityTest ==
                              FlexibilityTestType.sitAndReach
                          ? ExerciseType.sitAndReach
                          : ExerciseType.vSitAndReach;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show flexibility analysis results dialog
  void _showFlexibilityResults({
    required String formQuality,
    required String maxReach,
    required String score,
    required int reps,
    BenchmarkComparison? benchmarkComparison,
  }) {
    final theme = Theme.of(context);
    final isGoodForm = formQuality.toLowerCase() == 'excellent' ||
        formQuality.toLowerCase() == 'good';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.accessibility_new,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(_selectedFlexibilityTest == FlexibilityTestType.sitAndReach
                ? 'Sit & Reach Analysis'
                : 'V Sit & Reach Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Presidential Fitness Test Status
              if (benchmarkComparison != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: benchmarkComparison.passed
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: benchmarkComparison.passed
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            benchmarkComparison.passed
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: benchmarkComparison.passed
                                ? Colors.green
                                : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benchmarkComparison.passed
                                  ? 'Presidential Fitness: PASSED ✅'
                                  : 'Presidential Fitness: NOT MET ❌',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: benchmarkComparison.passed
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        benchmarkComparison.passed
                            ? 'Great job! You exceeded the benchmark by ${benchmarkComparison.differenceText}!'
                            : 'You need ${benchmarkComparison.differenceText} more to meet the Presidential Fitness Test standard.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Form Quality Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isGoodForm
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGoodForm
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isGoodForm
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: isGoodForm ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Form Quality: $formQuality',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isGoodForm
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGoodForm
                          ? 'Your flexibility form looks great! Keep it up.'
                          : 'Your form could use some improvement. Check the recommendations below.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Section - Tile Layout
              const Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Metrics Grid
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.repeat,
                          label: 'Repetitions',
                          value: '$reps',
                          unit: 'reps',
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.straighten,
                          label: 'Max Reach',
                          value: maxReach,
                          unit: 'cm',
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.star,
                          label: 'Score',
                          value: score,
                          unit: '/100',
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _currentFlexibilityMetrics != null
                            ? _buildMetricTile(
                                icon: Icons.grade,
                                label: 'Rating',
                                value: _currentFlexibilityMetrics!.rating,
                                unit: '',
                                theme: theme,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),

              // Issues Section - Collapsible
              if (_currentFlexibilityForm != null &&
                  _currentFlexibilityForm!.issues.isNotEmpty) ...[
                const SizedBox(height: 16),
                _CollapsibleSection(
                  title: 'Detected Issues',
                  icon: Icons.warning_amber,
                  iconColor: Colors.orangeAccent,
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  borderColor: Colors.orangeAccent.withValues(alpha: 0.3),
                  initiallyExpanded: false,
                  children: _currentFlexibilityForm!.issues
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '\u2022',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  issue,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // Recommendations Section - Collapsible
              if (_currentFlexibilityForm != null &&
                  _currentFlexibilityForm!.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _CollapsibleSection(
                  title: 'How to Improve',
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.greenAccent,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  borderColor: Colors.greenAccent.withValues(alpha: 0.3),
                  initiallyExpanded: false,
                  children: _currentFlexibilityForm!.recommendations
                      .map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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

  /// Show dialog to configure age and gender for Presidential Fitness Test
  Future<void> _showConfigureProfileDialog() async {
    final theme = Theme.of(context);
    int? selectedAge = _userAge;
    Gender? selectedGender = _userGender;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Presidential Fitness Test Setup'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set your age and gender to see how you compare to Presidential Fitness Test standards!',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Age Selection
              Text(
                'Age',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedAge,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select your age'),
                items: List.generate(12, (index) => index + 6)
                    .map((age) => DropdownMenuItem(
                          value: age,
                          child: Text('$age years'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedAge = value);
                },
              ),
              const SizedBox(height: 16),

              // Gender Selection
              Text(
                'Gender',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Gender>(
                value: selectedGender,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select your gender'),
                items: const [
                  DropdownMenuItem(
                    value: Gender.male,
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: Gender.female,
                    child: Text('Female'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => selectedGender = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedAge != null && selectedGender != null
                  ? () => Navigator.pop(context, {
                        'age': selectedAge,
                        'gender': selectedGender,
                      })
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _userPrefsService.saveAge(result['age']);
      await _userPrefsService.saveGender(result['gender']);
      await _loadUserData();
      _showSuccess(
          'Profile configured! Presidential Fitness Test benchmarks are now active.');
    }
  }

  /// Build benchmark info widgets for display under rep counter
  List<Widget> _buildBenchmarkInfo({bool isVideoView = false}) {
    final repCount = _repCounter?.repCount ?? 0;
    if (repCount == 0) return [];

    BenchmarkComparison? comparison;

    if (_selectedExercise == ExerciseType.sitUp) {
      comparison = PresidentialFitnessBenchmarks.compareSitUps(
        reps: repCount,
        age: _userAge!,
        gender: _userGender!,
      );
    } else if (_selectedExercise == ExerciseType.pullUp) {
      comparison = PresidentialFitnessBenchmarks.comparePullUps(
        reps: repCount,
        age: _userAge!,
        gender: _userGender!,
      );
    } else if (_selectedExercise == ExerciseType.pushUp) {
      // Push-ups don't have a benchmark in Presidential Fitness Test
      return [];
    }

    if (comparison == null) return [];

    final theme = Theme.of(context);
    final onColor = isVideoView
        ? theme.colorScheme.onTertiary
        : theme.colorScheme.onPrimary;

    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: comparison.passed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: comparison.passed
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.red.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comparison.passed ? Icons.check_circle : Icons.cancel,
                  color: onColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  comparison.passed ? 'PASSED!' : 'NOT MET',
                  style: TextStyle(
                    color: onColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              comparison.passed
                  ? '+${comparison.differenceText} above'
                  : '${comparison.differenceText} needed',
              style: TextStyle(
                color: onColor.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Presidential Fitness Test',
              style: TextStyle(
                color: onColor.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildFlexibilityMetricsOverlay() {
    if (_currentFlexibilityMetrics == null && _currentFlexibilityForm == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final metrics = _currentFlexibilityMetrics;
    final formMetrics = _currentFlexibilityForm;

    return Positioned(
      top: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withValues(alpha: 0.95),
              Colors.deepPurple.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with rep counter
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFlexibilityTest == FlexibilityTestType.sitAndReach
                        ? 'SIT & REACH'
                        : 'V SIT & REACH',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.repeat,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_flexibilityRepCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Metrics
            if (metrics != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFlexibilityMetricItem(
                    icon: Icons.straighten,
                    label: 'Reach',
                    value: '${metrics.reachDistance.toStringAsFixed(1)} cm',
                    theme: theme,
                  ),
                  _buildFlexibilityMetricItem(
                    icon: Icons.trending_up,
                    label: 'Max Reach',
                    value: '${metrics.maxReachDistance.toStringAsFixed(1)} cm',
                    theme: theme,
                  ),
                  _buildFlexibilityMetricItem(
                    icon: Icons.star,
                    label: 'Score',
                    value: '${metrics.flexibilityScore.toStringAsFixed(0)}/100',
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFlexibilityMetricItem(
                    icon: Icons.grade,
                    label: 'Rating',
                    value: metrics.rating,
                    theme: theme,
                  ),
                  _buildFlexibilityMetricItem(
                    icon: Icons.accessibility,
                    label: 'Hamstring',
                    value:
                        '${metrics.hamstringFlexibility.toStringAsFixed(0)}°',
                    theme: theme,
                  ),
                ],
              ),
            ],
            // Form Quality
            if (formMetrics != null) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white54, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getFlexibilityFormQualityIcon(formMetrics.overallQuality),
                    color: _getFlexibilityFormQualityColor(
                        formMetrics.overallQuality),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Form Quality: ${formMetrics.overallQuality.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formMetrics.qualityScore.toStringAsFixed(0)}/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Multi-angle pose analysis section
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assessment, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'MULTI-ANGLE ANALYSIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildAngleAnalysisRow(
                      'Front View',
                      Icons.person,
                      formMetrics.legSymmetry,
                      'Leg alignment & symmetry',
                    ),
                    const SizedBox(height: 6),
                    _buildAngleAnalysisRow(
                      'Side View',
                      Icons.switch_left,
                      formMetrics.backAlignment,
                      'Back posture & reach angle',
                    ),
                    const SizedBox(height: 6),
                    _buildAngleAnalysisRow(
                      'Legs',
                      Icons.accessibility,
                      formMetrics.kneeExtension,
                      'Knee extension quality',
                    ),
                    const SizedBox(height: 6),
                    _buildAngleAnalysisRow(
                      'Upper Body',
                      Icons.accessibility_new,
                      formMetrics.shoulderRelaxation,
                      'Shoulder & neck position',
                    ),
                  ],
                ),
              ),
              // Issues section
              if (formMetrics.issues.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orangeAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'DETECTED ISSUES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...formMetrics.issues.map((issue) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '\u2022',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    issue,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              // Recommendations section
              if (formMetrics.recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.greenAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'HOW TO IMPROVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...formMetrics.recommendations.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.greenAccent,
                                  size: 12,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
            if (!_baselineSet) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Get into starting position to set baseline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlexibilityMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  IconData _getFlexibilityFormQualityIcon(FlexibilityFormQuality quality) {
    switch (quality) {
      case FlexibilityFormQuality.excellent:
        return Icons.sentiment_very_satisfied;
      case FlexibilityFormQuality.good:
        return Icons.sentiment_satisfied;
      case FlexibilityFormQuality.fair:
        return Icons.sentiment_neutral;
      case FlexibilityFormQuality.poor:
        return Icons.sentiment_dissatisfied;
    }
  }

  Color _getFlexibilityFormQualityColor(FlexibilityFormQuality quality) {
    switch (quality) {
      case FlexibilityFormQuality.excellent:
        return Colors.greenAccent;
      case FlexibilityFormQuality.good:
        return Colors.lightGreenAccent;
      case FlexibilityFormQuality.fair:
        return Colors.orangeAccent;
      case FlexibilityFormQuality.poor:
        return Colors.redAccent;
    }
  }

  /// Build angle analysis row for multi-angle pose analysis
  Widget _buildAngleAnalysisRow(
    String viewName,
    IconData icon,
    double score,
    String description,
  ) {
    final percentage = (score * 100).toInt();
    Color scoreColor;
    String status;

    if (score >= 0.85) {
      scoreColor = Colors.greenAccent;
      status = 'Excellent';
    } else if (score >= 0.70) {
      scoreColor = Colors.lightGreenAccent;
      status = 'Good';
    } else if (score >= 0.55) {
      scoreColor = Colors.orangeAccent;
      status = 'Fair';
    } else {
      scoreColor = Colors.redAccent;
      status = 'Needs Work';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                viewName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scoreColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a metric tile for the flexibility analysis
  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build a shuttle run metric for the camera overlay
  Widget _buildShuttleMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Get color based on quality
  Color _getQualityColor(ShuttleFormQuality? quality) {
    if (quality == null) return Colors.grey;
    switch (quality) {
      case ShuttleFormQuality.excellent:
        return Colors.green;
      case ShuttleFormQuality.good:
        return Colors.lightGreen;
      case ShuttleFormQuality.fair:
        return Colors.orange;
      case ShuttleFormQuality.poor:
        return Colors.red;
    }
  }
}

/// Collapsible section widget for displaying issues and recommendations
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: widget.borderColor,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
