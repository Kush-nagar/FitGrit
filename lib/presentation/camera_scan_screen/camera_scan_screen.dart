import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/confidence_overlay_widget.dart';
import './widgets/recognition_result_sheet.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  XFile? _capturedImage;

  // Recognition data
  String? _recognizedFood;
  double? _confidenceScore;
  int? _estimatedCalories;
  bool _showConfidenceOverlay = false;

  // Animation controllers
  late AnimationController _captureAnimationController;
  late AnimationController _overlayAnimationController;
  late Animation<double> _captureScaleAnimation;
  late Animation<double> _overlayFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _captureScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _captureAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _overlayFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeIn,
      ),
    );
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog();
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showNoCameraDialog();
        return;
      }

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!kIsWeb) {
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (e) {
          // Silently handle unsupported features
        }
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showCameraErrorDialog();
    }
  }

  Future<void> _toggleFlash() async {
    if (kIsWeb || _cameraController == null) return;

    HapticFeedback.lightImpact();
    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      setState(() {
        _isFlashOn = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    HapticFeedback.mediumImpact();
    _captureAnimationController.forward().then((_) {
      _captureAnimationController.reverse();
    });

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo;
      });

      await _processImage(photo);
    } catch (e) {
      _showCaptureErrorDialog();
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isProcessing = true;
        });

        await _processImage(image);

        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showGalleryErrorDialog();
    }
  }

  Future<void> _processImage(XFile image) async {
    // Simulate AI processing with hardcoded confidence scores
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock food recognition data
    final mockFoods = [
      {'name': 'Grilled Chicken Breast', 'confidence': 0.92, 'calories': 165},
      {'name': 'Caesar Salad', 'confidence': 0.88, 'calories': 184},
      {'name': 'Salmon Fillet', 'confidence': 0.85, 'calories': 206},
      {'name': 'Avocado Toast', 'confidence': 0.79, 'calories': 250},
      {'name': 'Greek Yogurt Bowl', 'confidence': 0.73, 'calories': 150},
      {'name': 'Quinoa Bowl', 'confidence': 0.68, 'calories': 222},
      {'name': 'Protein Smoothie', 'confidence': 0.55, 'calories': 180},
      {'name': 'Mixed Vegetables', 'confidence': 0.48, 'calories': 85},
    ];

    final randomFood = (mockFoods..shuffle()).first;

    setState(() {
      _recognizedFood = randomFood['name'] as String;
      _confidenceScore = randomFood['confidence'] as double;
      _estimatedCalories = randomFood['calories'] as int;
      _showConfidenceOverlay = true;
    });

    _overlayAnimationController.forward();

    // Show result sheet after brief delay
    await Future.delayed(const Duration(milliseconds: 800));
    _showRecognitionResultSheet();
  }

  void _showRecognitionResultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecognitionResultSheet(
        foodName: _recognizedFood!,
        confidence: _confidenceScore!,
        calories: _estimatedCalories!,
        imagePath: _capturedImage!.path,
        onConfirm: _confirmRecognition,
        onEdit: _editRecognition,
        onManualEntry: _switchToManualEntry,
      ),
    );
  }

  void _confirmRecognition() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    Navigator.pushNamed(context, '/food-log-history-screen');
  }

  void _editRecognition() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    // Navigate to edit screen (would be implemented separately)
  }

  void _switchToManualEntry() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    // Navigate to manual entry screen (would be implemented separately)
  }

  void _retakePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _capturedImage = null;
      _recognizedFood = null;
      _confidenceScore = null;
      _estimatedCalories = null;
      _showConfidenceOverlay = false;
    });
    _overlayAnimationController.reset();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Please grant camera permission in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Camera Found'),
        content: const Text('No camera device was detected on your device.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCameraErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: const Text('Failed to initialize camera. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeCamera();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCaptureErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capture Failed'),
        content: const Text('Failed to capture photo. Please try again.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGalleryErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gallery Access Failed'),
        content: const Text('Failed to access gallery. Please try again.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _captureAnimationController.dispose();
    _overlayAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.transparent,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'close',
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          tooltip: 'Close',
        ),
        actions: [
          if (!kIsWeb && _isCameraInitialized)
            IconButton(
              icon: CustomIconWidget(
                iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                color: _isFlashOn ? theme.colorScheme.primary : Colors.white,
                size: 28,
              ),
              onPressed: _toggleFlash,
              tooltip: _isFlashOn ? 'Flash On' : 'Flash Off',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            CameraPreviewWidget(
              controller: _cameraController!,
              showGrid: true,
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // Confidence Overlay
          if (_showConfidenceOverlay && _recognizedFood != null)
            FadeTransition(
              opacity: _overlayFadeAnimation,
              child: ConfidenceOverlayWidget(
                foodName: _recognizedFood!,
                confidence: _confidenceScore!,
              ),
            ),

          // Camera Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CameraControlsWidget(
              isProcessing: _isProcessing,
              captureAnimation: _captureScaleAnimation,
              onCapture: _capturePhoto,
              onGallery: _pickFromGallery,
              onRetake: _capturedImage != null ? _retakePhoto : null,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/camera-scan-screen',
        onNavigate: (route) {
          if (route != '/camera-scan-screen') {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
