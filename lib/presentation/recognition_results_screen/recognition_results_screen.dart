import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/add_ingredient_modal_widget.dart';
import './widgets/captured_image_header_widget.dart';
import './widgets/empty_recognition_widget.dart';
import './widgets/ingredient_chip_widget.dart';
import './widgets/loading_skeleton_widget.dart';

class RecognitionResultsScreen extends StatefulWidget {
  const RecognitionResultsScreen({super.key});

  @override
  State<RecognitionResultsScreen> createState() =>
      _RecognitionResultsScreenState();
}

class _RecognitionResultsScreenState extends State<RecognitionResultsScreen> {
  bool _isLoading = true;
  String? _capturedImagePath;
  List<Map<String, dynamic>> _recognizedIngredients = [];

  /// Minimum confidence threshold to keep a detected label (adjustable)
  final double _minConfidence = 0.35;

  @override
  void initState() {
    super.initState();
    _initializeRecognition();
  }

  String _normalizeName(String raw) {
    final lower = raw.trim().toLowerCase();
    // basic plural -> singular naive handling
    if (lower.endsWith('es')) return lower.substring(0, lower.length - 2);
    if (lower.endsWith('s')) return lower.substring(0, lower.length - 1);
    return lower;
  }

  Map<String, dynamic> _makeIngredientObject({
    required String name,
    double confidence = 1.0,
    String category = 'detected',
    dynamic boundingBox,
  }) {
    final normalized = _normalizeName(name);
    return {
      'id': DateTime.now().millisecondsSinceEpoch ^ normalized.hashCode,
      'name': normalized[0].toUpperCase() + normalized.substring(1),
      'confidence': (confidence).clamp(0.0, 1.0),
      'category': category,
      'boundingBox': boundingBox,
    };
  }

  Future<void> _initializeRecognition() async {
    // Read navigation args once the widget is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      // Defaults
      List<Map<String, dynamic>> items = [];

      if (args != null) {
        // Image path (optional)
        _capturedImagePath = args['imagePath'] as String?;

        // Manual ingredients (from manual entry)
        if (args['manualIngredients'] != null) {
          final List<dynamic> manual =
              args['manualIngredients'] as List<dynamic>;
          for (var m in manual) {
            if (m is String && m.trim().isNotEmpty) {
              items.add(
                _makeIngredientObject(
                  name: m,
                  confidence: 1.0,
                  category: 'manual',
                ),
              );
            }
          }
        }

        // Detected ingredients (from Gemini API)
        if (args['detectedIngredients'] != null) {
          final List<dynamic> detected = List<dynamic>.from(
            args['detectedIngredients'] as List<dynamic>,
          );
          for (var d in detected) {
            try {
              final rawName = (d['name'] ?? d['label'] ?? '').toString();
              final conf = (d['confidence'] ?? d['score'] ?? 0.0) as num;
              final box = d['boundingBox'] ?? d['boundingPoly'];

              if (rawName.trim().isEmpty) continue;

              if (conf.toDouble() < _minConfidence) {
                // skip low-confidence detections
                continue;
              }

              items.add(
                _makeIngredientObject(
                  name: rawName,
                  confidence: conf.toDouble(),
                  category: 'detected',
                  boundingBox: box,
                ),
              );
            } catch (_) {
              // ignore malformed entries
              continue;
            }
          }
        }
      }

      // Remove duplicates by name (keep highest confidence)
      final Map<String, Map<String, dynamic>> dedup = {};
      for (var it in items) {
        final key = (it['name'] as String).toLowerCase();
        if (!dedup.containsKey(key) ||
            (it['confidence'] as double) >
                (dedup[key]!['confidence'] as double)) {
          dedup[key] = it;
        }
      }

      setState(() {
        _recognizedIngredients = dedup.values.toList();
        _isLoading = false;
      });
    });
  }

  void _removeIngredient(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _recognizedIngredients.removeAt(index);
    });
  }

  void _addIngredient(String ingredientName) {
    final newIngredient = _makeIngredientObject(
      name: ingredientName,
      confidence: 1.0, // Manual additions assumed high confidence
      category: 'manual',
    );

    setState(() {
      _recognizedIngredients.add(newIngredient);
    });

    HapticFeedback.lightImpact();
  }

  void _showAddIngredientModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddIngredientModalWidget(onAddIngredient: _addIngredient),
    );
  }

  void _editIngredientName(int index, String currentName) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Ingredient',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ingredient name',
            hintText: 'Enter ingredient name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _recognizedIngredients[index]['name'] =
                      newName[0].toUpperCase() + newName.substring(1);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _retakePhoto() {
    Navigator.pushNamed(context, '/camera-scan-screen').then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _capturedImagePath = result['imagePath'] as String?;
          _recognizedIngredients =
              result['detectedIngredients'] as List<Map<String, dynamic>>? ??
                  [];
          _isLoading = false;
        });
      }
    });
  }

  void _tryAgainRecognition() {
    setState(() {
      _isLoading = true;
      _recognizedIngredients.clear();
    });
    _initializeRecognition();
  }

  void _findRecipes() {
    if (_recognizedIngredients.isNotEmpty) {
      final ingredientNames = _recognizedIngredients
          .map((ingredient) => ingredient['name'] as String)
          .toList();

      // TODO: Navigate to recipe screen when implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Finding recipes with ${ingredientNames.length} ingredients...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addMoreIngredients() async {
    final result = await Navigator.pushNamed(
      context,
      '/camera-scan-screen',
      arguments: {
        'existingIngredients': _recognizedIngredients,
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      final newIngredients =
          result['detectedIngredients'] as List<Map<String, dynamic>>? ?? [];

      setState(() {
        _recognizedIngredients.addAll(newIngredients);

        // Deduplicate by name
        final dedup = <String, Map<String, dynamic>>{};
        for (var it in _recognizedIngredients) {
          final key = (it['name'] as String).toLowerCase();
          if (!dedup.containsKey(key) ||
              (it['confidence'] as double) >
                  (dedup[key]!['confidence'] as double)) {
            dedup[key] = it;
          }
        }
        _recognizedIngredients = dedup.values.toList();
      });
    }
  }

  void _saveToInventory() {
    if (_recognizedIngredients.isEmpty) return;

    // TODO: Navigate to inventory screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Saved ${_recognizedIngredients.length} ingredients to inventory'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareIngredients() {
    if (_recognizedIngredients.isEmpty) return;

    final ingredientNames = _recognizedIngredients
        .map((ingredient) => ingredient['name'] as String)
        .join(', ');

    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: $ingredientNames'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_recognizedIngredients.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have selected ingredients. Are you sure you want to go back?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Discard',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Recognition Results',
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushReplacementNamed('/camera-scan-screen');
                }
              }
            },
          ),
          actions: [
            if (!_isLoading && _recognizedIngredients.isNotEmpty)
              IconButton(
                onPressed: _tryAgainRecognition,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                tooltip: 'Refresh',
              ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                _tryAgainRecognition();
              },
              child: Column(
                children: [
                  // Header with captured image
                  if (_capturedImagePath != null)
                    CapturedImageHeaderWidget(
                      imagePath: _capturedImagePath,
                      onRetake: _retakePhoto,
                    ),

                  // Main content
                  Expanded(
                    child: _isLoading
                        ? const LoadingSkeletonWidget()
                        : _recognizedIngredients.isEmpty
                            ? EmptyRecognitionWidget(
                                onTryAgain: _tryAgainRecognition,
                                onAddManually: _showAddIngredientModal,
                              )
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  left: 4.w,
                                  right: 4.w,
                                  top: 2.h,
                                  bottom: 22.h, // Space for floating buttons
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Recognized Ingredients',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 0.5.h),
                                            Text(
                                              '${_recognizedIngredients.length} items detected',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _showAddIngredientModal,
                                          icon: CustomIconWidget(
                                            iconName: 'add',
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                          label: const Text('Add'),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      child: Padding(
                                        padding: EdgeInsets.all(4.w),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 2.w,
                                              runSpacing: 1.5.h,
                                              children: _recognizedIngredients
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                final index = entry.key;
                                                final ingredient = entry.value;

                                                return Dismissible(
                                                  key: Key(
                                                    'ingredient_${ingredient['id']}',
                                                  ),
                                                  direction: DismissDirection
                                                      .endToStart,
                                                  onDismissed: (_) =>
                                                      _removeIngredient(index),
                                                  background: Container(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    padding: EdgeInsets.only(
                                                      right: 4.w,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme.error,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: CustomIconWidget(
                                                      iconName: 'delete',
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  child: IngredientChipWidget(
                                                    ingredientName:
                                                        ingredient['name']
                                                            as String,
                                                    confidence: (ingredient[
                                                                'confidence']
                                                            as num)
                                                        .toDouble(),
                                                    onRemove: () =>
                                                        _removeIngredient(
                                                            index),
                                                    onLongPress: () =>
                                                        _editIngredientName(
                                                      index,
                                                      ingredient['name']
                                                          as String,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 2.h),

                                            // Confidence legend
                                            Container(
                                              padding: EdgeInsets.all(3.w),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Wrap(
                                                spacing: 3.w,
                                                runSpacing: 1.2.h,
                                                children: [
                                                  _buildConfidenceLegend(
                                                    color: theme
                                                        .colorScheme.tertiary,
                                                    label: 'High (80%+)',
                                                  ),
                                                  _buildConfidenceLegend(
                                                    color: theme
                                                        .colorScheme.secondary,
                                                    label: 'Medium (50-80%)',
                                                  ),
                                                  _buildConfidenceLegend(
                                                    color:
                                                        theme.colorScheme.error,
                                                    label: 'Low (<50%)',
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: 2.h),

                                            // Helper text
                                            Text(
                                              'Tip: Long-press an item to edit its name. Swipe left to remove.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),

            // Floating action buttons at the bottom
            if (!_isLoading && _recognizedIngredients.isNotEmpty)
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 3.h,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6.5.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 255, 145, 0), Color.fromARGB(255, 255, 145, 0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(255, 255, 136, 0),
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _saveToInventory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.5.h),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'restaurant',
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Log Food',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Container(
                        height: 6.5.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF9C27B0),
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _findRecipes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.5.h),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'restaurant_menu',
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Recipes',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: CustomBottomBar(
          currentRoute: '/recognition-results-screen',
          onNavigate: (route) {
            if (route != '/recognition-results-screen') {
              Navigator.pushReplacementNamed(context, route);
            }
          },
        ),
      ),
    );
  }

  Widget _buildConfidenceLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
