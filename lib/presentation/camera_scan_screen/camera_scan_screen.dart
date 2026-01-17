import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../services/gemini_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_preview_widget.dart';

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

  late GeminiService _geminiService;

  // Recognition data - now supports multiple foods
  List<Map<String, dynamic>> _recognizedFoods = [];
  bool _showConfidenceOverlay = false;

  // Animation controllers
  late AnimationController _captureAnimationController;
  late AnimationController _overlayAnimationController;
  late Animation<double> _captureScaleAnimation;
  late Animation<double> _overlayFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Gemini Service with configuration
    _geminiService = GeminiService(
      apiKey: AppConfig.geminiApiKey,
      model: AppConfig.geminiModel,
      maxDimension: AppConfig.maxImageDimension,
    );

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
    try {
      // Call Gemini API to detect multiple foods
      final rawResults = await _geminiService.detectFoods(image.path);

      if (rawResults.isEmpty) {
        _showNoFoodDetectedDialog();
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Sort by confidence and keep all results (can filter by min threshold if needed)
      final sortedResults = List<Map<String, dynamic>>.from(rawResults)
        ..sort((a, b) => (b['confidence'] as double)
            .compareTo(a['confidence'] as double));

      // Filter out low confidence items (optional, threshold can be adjusted)
      final minConfidence = 0.3;
      final filteredResults = sortedResults
          .where((item) => (item['confidence'] as double) >= minConfidence)
          .toList();

      if (filteredResults.isEmpty) {
        _showNoFoodDetectedDialog();
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _recognizedFoods = filteredResults;
        _showConfidenceOverlay = true;
      });

      _overlayAnimationController.forward();

      // Show result sheet after brief delay
      await Future.delayed(const Duration(milliseconds: 1200));
      _showRecognitionResultSheet();
    } catch (e) {
      _showProcessingErrorDialog(e.toString());
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showRecognitionResultSheet() {
    // Navigate to recognition results screen with all detected foods
    Navigator.pushNamed(
      context,
      '/recognition-results-screen',
      arguments: {
        'imagePath': _capturedImage!.path,
        'imageSource': 'camera',
        'detectedIngredients': _recognizedFoods.map((food) => {
          'name': food['name'] as String,
          'confidence': food['confidence'] as double,
          'category': 'detected',
        }).toList(),
      },
    );
  }

  void _retakePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _capturedImage = null;
      _recognizedFoods = [];
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

  void _showNoFoodDetectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Food Detected'),
        content: const Text(
            'Could not detect any food items in the image. Please try again with a clearer photo.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProcessingErrorDialog(String error) {
    // Check if it's an API configuration error
    final isApiError = error.contains('API') ||
        error.contains('403') ||
        error.contains('denied');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApiError ? 'API Configuration Error' : 'Processing Failed',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed to process image:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (isApiError) ...[
              const SizedBox(height: 16),
              const Text(
                'To fix this:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Enable the Generative Language API in Google Cloud Console\n'
                '2. Verify your API key is valid\n'
                '3. Check API quota limits',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _retakePhoto();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleFoodsOverlay() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.95),
            theme.colorScheme.secondary.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_recognizedFoods.length} Food Item${_recognizedFoods.length > 1 ? 's' : ''} Detected',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_recognizedFoods.length, (index) {
            final food = _recognizedFoods[index];
            final foodName = food['name'] as String;
            final confidence = (food['confidence'] as double) * 100;
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < _recognizedFoods.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: confidence / 100,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.8),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${confidence.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
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

          // Confidence Overlay - Multiple Foods
          if (_showConfidenceOverlay && _recognizedFoods.isNotEmpty)
            Positioned(
              top: 120,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _overlayFadeAnimation,
                child: _buildMultipleFoodsOverlay(),
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
