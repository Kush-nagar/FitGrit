// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/date_filter_chips_widget.dart';
import './widgets/date_section_header_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/food_entry_card_widget.dart';
import './widgets/meal_type_filter_widget.dart';
import './widgets/search_bar_widget.dart';

class FoodLogHistoryScreen extends StatefulWidget {
  const FoodLogHistoryScreen({super.key});

  @override
  State<FoodLogHistoryScreen> createState() => _FoodLogHistoryScreenState();
}

class _FoodLogHistoryScreenState extends State<FoodLogHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedDateFilter = 'Today';
  final List<String> _selectedMealTypes = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  // Mock data for food entries grouped by date
  final List<Map<String, dynamic>> _allFoodEntries = [
    {
      'date': 'Today, Dec 14',
      'entries': [
        {
          'id': 1,
          'name': 'Grilled Chicken Salad',
          'portion': '1 bowl (350g)',
          'calories': 420,
          'mealType': 'Lunch',
          'image':
              'https://images.unsplash.com/photo-1574926054530-540288c8e678',
          'semanticLabel':
              'Fresh green salad bowl with grilled chicken strips, cherry tomatoes, and mixed greens',
          'timestamp': '12:30 PM',
        },
        {
          'id': 2,
          'name': 'Greek Yogurt with Berries',
          'portion': '1 cup (200g)',
          'calories': 180,
          'mealType': 'Breakfast',
          'image':
              'https://images.unsplash.com/photo-1670331553160-0cfbe585edfa',
          'semanticLabel':
              'White bowl of creamy Greek yogurt topped with fresh blueberries and strawberries',
          'timestamp': '8:00 AM',
        },
        {
          'id': 3,
          'name': 'Almonds',
          'portion': '1 handful (28g)',
          'calories': 160,
          'mealType': 'Snacks',
          'image':
              'https://img.rocket.new/generatedImages/rocket_gen_img_1780c4e03-1765005038973.png',
          'semanticLabel':
              'Pile of raw whole almonds with brown shells on white surface',
          'timestamp': '3:00 PM',
        },
      ],
    },
    {
      'date': 'Yesterday, Dec 13',
      'entries': [
        {
          'id': 4,
          'name': 'Salmon with Vegetables',
          'portion': '1 fillet (200g)',
          'calories': 520,
          'mealType': 'Dinner',
          'image':
              'https://images.unsplash.com/photo-1678354830591-b5debb4e37c8',
          'semanticLabel':
              'Grilled salmon fillet with roasted vegetables including broccoli and carrots on white plate',
          'timestamp': '7:00 PM',
        },
        {
          'id': 5,
          'name': 'Oatmeal with Banana',
          'portion': '1 bowl (250g)',
          'calories': 280,
          'mealType': 'Breakfast',
          'image':
              'https://images.unsplash.com/photo-1630234674868-404d00118f7e',
          'semanticLabel':
              'Bowl of creamy oatmeal topped with sliced bananas and honey drizzle',
          'timestamp': '7:30 AM',
        },
        {
          'id': 6,
          'name': 'Turkey Sandwich',
          'portion': '1 sandwich',
          'calories': 380,
          'mealType': 'Lunch',
          'image':
              'https://images.unsplash.com/photo-1673646961267-a8247d80526c',
          'semanticLabel':
              'Whole wheat sandwich with turkey slices, lettuce, and tomato on wooden board',
          'timestamp': '1:00 PM',
        },
      ],
    },
    {
      'date': 'Dec 12, 2024',
      'entries': [
        {
          'id': 7,
          'name': 'Protein Smoothie',
          'portion': '1 glass (300ml)',
          'calories': 250,
          'mealType': 'Breakfast',
          'image':
              'https://images.unsplash.com/photo-1588368254622-8dda24870430',
          'semanticLabel':
              'Purple smoothie in clear glass with banana and berries visible',
          'timestamp': '8:30 AM',
        },
        {
          'id': 8,
          'name': 'Quinoa Bowl',
          'portion': '1 bowl (300g)',
          'calories': 450,
          'mealType': 'Lunch',
          'image':
              'https://images.unsplash.com/photo-1623428187425-873f16e10554',
          'semanticLabel':
              'Colorful quinoa bowl with roasted vegetables, chickpeas, and tahini dressing',
          'timestamp': '12:00 PM',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    _filteredEntries = List.from(_allFoodEntries);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _currentPage < 3) {
        _loadMoreEntries();
      }
    }
  }

  Future<void> _loadMoreEntries() async {
    setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshEntries() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allFoodEntries);

    // Apply date filter
    if (_selectedDateFilter == 'Today') {
      filtered = filtered
          .where((group) => group['date'].toString().contains('Today'))
          .toList();
    } else if (_selectedDateFilter == 'Week') {
      filtered = filtered.take(2).toList();
    }

    // Apply meal type filter
    if (_selectedMealTypes.isNotEmpty) {
      filtered = filtered
          .map((group) {
            final filteredEntries = (group['entries'] as List).where((entry) {
              return _selectedMealTypes.contains(entry['mealType']);
            }).toList();

            return filteredEntries.isNotEmpty
                ? {...group, 'entries': filteredEntries}
                : null;
          })
          .where((group) => group != null)
          .cast<Map<String, dynamic>>()
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .map((group) {
            final filteredEntries = (group['entries'] as List).where((entry) {
              return (entry['name'] as String)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
            }).toList();

            return filteredEntries.isNotEmpty
                ? {...group, 'entries': filteredEntries}
                : null;
          })
          .where((group) => group != null)
          .cast<Map<String, dynamic>>()
          .toList();
    }

    setState(() => _filteredEntries = filtered);
  }

  void _onDateFilterSelected(String filter) {
    setState(() => _selectedDateFilter = filter);
    _applyFilters();
  }

  void _onMealTypeToggle(String mealType) {
    setState(() {
      if (_selectedMealTypes.contains(mealType)) {
        _selectedMealTypes.remove(mealType);
      } else {
        _selectedMealTypes.add(mealType);
      }
    });
    _applyFilters();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onClearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _onEditEntry(Map<String, dynamic> entry) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Editing: ${entry['name']}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDeleteEntry(Map<String, dynamic> entry) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete "${entry['name']}"?',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Deleted: ${entry['name']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.surface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _onDuplicateEntry(Map<String, dynamic> entry) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Duplicated: ${entry['name']}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onViewDetails(Map<String, dynamic> entry) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 10.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImageWidget(
                    imageUrl: entry['image'] as String,
                    width: double.infinity,
                    height: 30.h,
                    fit: BoxFit.cover,
                    semanticLabel: entry['semanticLabel'] as String,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  entry['name'] as String,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${entry['mealType']} • ${entry['timestamp']}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),
                _buildNutritionRow(theme, 'Calories',
                    '${entry['calories']} cal', AppTheme.accentOrange),
                _buildNutritionRow(
                    theme, 'Protein', '32g', AppTheme.accentPurple),
                _buildNutritionRow(theme, 'Carbs', '45g', AppTheme.accentBlue),
                _buildNutritionRow(theme, 'Fats', '18g', AppTheme.primaryLime),
                SizedBox(height: 3.h),
                Text(
                  'Portion Size',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  entry['portion'] as String,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionRow(
      ThemeData theme, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _onAddMeal() {
    Navigator.pushNamed(context, '/camera-scan-screen');
  }

  int _getTotalCaloriesForDate(List<dynamic> entries) {
    return entries.fold(0, (sum, entry) => sum + (entry['calories'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEntries = _filteredEntries.isNotEmpty;

    return Scaffold(
      appBar: const CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Food Log',
        centerTitle: false,
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onSearch: _onSearch,
            onClear: _onClearSearch,
          ),
          DateFilterChipsWidget(
            selectedFilter: _selectedDateFilter,
            onFilterSelected: _onDateFilterSelected,
          ),
          MealTypeFilterWidget(
            selectedMealTypes: _selectedMealTypes,
            onMealTypeToggle: _onMealTypeToggle,
          ),
          Expanded(
            child: hasEntries
                ? RefreshIndicator(
                    onRefresh: _refreshEntries,
                    color: theme.colorScheme.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          _filteredEntries.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredEntries.length) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }

                        final dateGroup = _filteredEntries[index];
                        final entries = dateGroup['entries'] as List;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateSectionHeaderWidget(
                              date: dateGroup['date'] as String,
                              totalCalories: _getTotalCaloriesForDate(entries),
                              entryCount: entries.length,
                            ),
                            ...entries.map((entry) => FoodEntryCardWidget(
                                  entry: entry as Map<String, dynamic>,
                                  onEdit: () => _onEditEntry(entry),
                                  onDelete: () => _onDeleteEntry(entry),
                                  onDuplicate: () => _onDuplicateEntry(entry),
                                  onViewDetails: () => _onViewDetails(entry),
                                )),
                          ],
                        );
                      },
                    ),
                  )
                : EmptyStateWidget(onAddMeal: _onAddMeal),
          ),
        ],
      ),
      floatingActionButton: hasEntries
          ? FloatingActionButton(
              onPressed: _onAddMeal,
              tooltip: 'Add Food Entry',
              child: CustomIconWidget(
                iconName: 'add',
                size: 28,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : null,
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/food-log-history-screen',
        onNavigate: (route) => Navigator.pushNamed(context, route),
      ),
    );
  }
}
