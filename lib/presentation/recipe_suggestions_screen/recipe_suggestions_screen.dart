// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/recipe_actions_bottom_sheet_widget.dart';
import './widgets/recipe_card_widget.dart';
import './widgets/search_bar_widget.dart';

class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  State<RecipeSuggestionsScreen> createState() =>
      _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  bool _isRefreshing = false;
  bool _showFavorites = false;
  Map<String, String> _selectedFilters = {};
  final List<String> _recentSearches = ['Pasta', 'Chicken', 'Salad'];

  // Mock recipe data
  final List<Map<String, dynamic>> _allRecipes = [
    {
      "id": 1,
      "title": "Grilled Chicken Salad",
      "image": "https://images.unsplash.com/photo-1627062815571-01d12fb35f91",
      "semanticLabel":
          "Fresh green salad with grilled chicken breast strips, cherry tomatoes, and mixed greens on a white plate",
      "cookingTime": "25 min",
      "difficulty": "Easy",
      "cuisine": "American",
      "dietaryRestriction": "Gluten-Free",
      "isFavorite": true,
      "ingredients": [
        "Chicken breast",
        "Mixed greens",
        "Cherry tomatoes",
        "Olive oil"
      ],
      "basedOnScan": true,
    },
    {
      "id": 2,
      "title": "Spaghetti Carbonara",
      "image": "https://images.unsplash.com/photo-1591972774172-084d6be1b72c",
      "semanticLabel":
          "Creamy spaghetti carbonara with bacon pieces and parmesan cheese in a white bowl",
      "cookingTime": "30 min",
      "difficulty": "Medium",
      "cuisine": "Italian",
      "dietaryRestriction": "None",
      "isFavorite": false,
      "ingredients": ["Spaghetti", "Eggs", "Bacon", "Parmesan cheese"],
      "basedOnScan": false,
    },
    {
      "id": 3,
      "title": "Vegetable Stir Fry",
      "image": "https://images.unsplash.com/photo-1733361206008-f5d6f9c03f46",
      "semanticLabel":
          "Colorful vegetable stir fry with broccoli, bell peppers, and carrots in a dark wok",
      "cookingTime": "20 min",
      "difficulty": "Easy",
      "cuisine": "Asian",
      "dietaryRestriction": "Vegan",
      "isFavorite": true,
      "ingredients": ["Broccoli", "Bell peppers", "Carrots", "Soy sauce"],
      "basedOnScan": true,
    },
    {
      "id": 4,
      "title": "Beef Tacos",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10a716858-1765095383119.png",
      "semanticLabel":
          "Three beef tacos with lettuce, tomatoes, and cheese on a wooden board",
      "cookingTime": "35 min",
      "difficulty": "Medium",
      "cuisine": "Mexican",
      "dietaryRestriction": "None",
      "isFavorite": false,
      "ingredients": ["Ground beef", "Taco shells", "Lettuce", "Cheese"],
      "basedOnScan": false,
    },
    {
      "id": 5,
      "title": "Quinoa Buddha Bowl",
      "image": "https://images.unsplash.com/photo-1623428188495-89c064ee061a",
      "semanticLabel":
          "Healthy buddha bowl with quinoa, roasted vegetables, avocado, and chickpeas",
      "cookingTime": "40 min",
      "difficulty": "Easy",
      "cuisine": "Mediterranean",
      "dietaryRestriction": "Vegan",
      "isFavorite": true,
      "ingredients": ["Quinoa", "Chickpeas", "Avocado", "Mixed vegetables"],
      "basedOnScan": false,
    },
    {
      "id": 6,
      "title": "Salmon Teriyaki",
      "image": "https://images.unsplash.com/photo-1732560607199-5dfa04a9c8d1",
      "semanticLabel":
          "Glazed salmon fillet with teriyaki sauce served with steamed rice and vegetables",
      "cookingTime": "30 min",
      "difficulty": "Medium",
      "cuisine": "Japanese",
      "dietaryRestriction": "Gluten-Free",
      "isFavorite": false,
      "ingredients": ["Salmon fillet", "Teriyaki sauce", "Rice", "Broccoli"],
      "basedOnScan": true,
    },
    {
      "id": 7,
      "title": "Margherita Pizza",
      "image": "https://images.unsplash.com/photo-1703784022146-b72677752ce5",
      "semanticLabel":
          "Classic margherita pizza with fresh mozzarella, basil leaves, and tomato sauce",
      "cookingTime": "45 min",
      "difficulty": "Hard",
      "cuisine": "Italian",
      "dietaryRestriction": "Vegetarian",
      "isFavorite": true,
      "ingredients": ["Pizza dough", "Mozzarella", "Tomatoes", "Basil"],
      "basedOnScan": false,
    },
    {
      "id": 8,
      "title": "Thai Green Curry",
      "image": "https://images.unsplash.com/photo-1586128737015-87894872e863",
      "semanticLabel":
          "Creamy green curry with vegetables and tofu in a white bowl with jasmine rice",
      "cookingTime": "35 min",
      "difficulty": "Medium",
      "cuisine": "Thai",
      "dietaryRestriction": "Vegan",
      "isFavorite": false,
      "ingredients": [
        "Green curry paste",
        "Coconut milk",
        "Tofu",
        "Vegetables"
      ],
      "basedOnScan": true,
    },
  ];

  List<Map<String, dynamic>> _filteredRecipes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredRecipes = List.from(_allRecipes);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more recipes (pagination simulation)
    }
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _allRecipes.where((recipe) {
        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          final titleMatch =
              (recipe['title'] as String).toLowerCase().contains(searchLower);
          final ingredientMatch = (recipe['ingredients'] as List).any(
            (ingredient) =>
                (ingredient as String).toLowerCase().contains(searchLower),
          );
          if (!titleMatch && !ingredientMatch) return false;
        }

        // Favorites filter
        if (_showFavorites && recipe['isFavorite'] != true) {
          return false;
        }

        // Cuisine filter
        if (_selectedFilters.containsKey('Cuisine Type')) {
          if (recipe['cuisine'] != _selectedFilters['Cuisine Type']) {
            return false;
          }
        }

        // Dietary restriction filter
        if (_selectedFilters.containsKey('Dietary Restrictions')) {
          if (recipe['dietaryRestriction'] !=
              _selectedFilters['Dietary Restrictions']) {
            return false;
          }
        }

        // Cooking time filter
        if (_selectedFilters.containsKey('Cooking Time')) {
          final timeFilter = _selectedFilters['Cooking Time'];
          final cookingTime =
              int.parse((recipe['cookingTime'] as String).split(' ')[0]);

          if (timeFilter == 'Under 20 min' && cookingTime >= 20) return false;
          if (timeFilter == '20-40 min' &&
              (cookingTime < 20 || cookingTime > 40)) {
            return false;
          }
          if (timeFilter == 'Over 40 min' && cookingTime <= 40) return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
      _filteredRecipes = List.from(_allRecipes);
    });

    Fluttertoast.showToast(
      msg: "Recipes updated based on recent scans",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleVoiceSearch() {
    Fluttertoast.showToast(
      msg: "Voice search activated",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        filterOptions: {
          'Cuisine Type': [
            'American',
            'Italian',
            'Asian',
            'Mexican',
            'Mediterranean',
            'Japanese',
            'Thai'
          ],
          'Dietary Restrictions': [
            'None',
            'Vegetarian',
            'Vegan',
            'Gluten-Free'
          ],
          'Cooking Time': ['Under 20 min', '20-40 min', 'Over 40 min'],
        },
        selectedFilters: _selectedFilters,
        onApplyFilters: (filters) {
          setState(() {
            _selectedFilters = filters;
            _filterRecipes();
          });
        },
      ),
    );
  }

  void _showRecipeActions(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipeActionsBottomSheetWidget(
        recipe: recipe,
        onSaveToFavorites: () {
          setState(() {
            recipe['isFavorite'] = !(recipe['isFavorite'] == true);
            _filterRecipes();
          });
          Fluttertoast.showToast(
            msg: recipe['isFavorite'] == true
                ? "Added to favorites"
                : "Removed from favorites",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        },
        onShare: () {
          Share.share(
            'Check out this recipe: ${recipe['title']}\n${recipe['image']}',
            subject: 'Recipe Suggestion',
          );
        },
        onAddToShoppingList: () {
          Fluttertoast.showToast(
            msg: "Ingredients added to shopping list",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        },
      ),
    );
  }

  void _navigateToRecipeDetail(Map<String, dynamic> recipe) {
    // Store scroll position
    final scrollPosition = _scrollController.position.pixels;

    // Navigate to detail screen (not implemented in this scope)
    Fluttertoast.showToast(
      msg: "Opening ${recipe['title']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    // Restore scroll position on return
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(scrollPosition);
      }
    });
  }

  List<String> _getActiveFiltersList() {
    List<String> filters = [];
    _selectedFilters.forEach((key, value) {
      filters.add(value);
    });
    return filters;
  }

  Widget _buildRecipeGrid() {
    if (_filteredRecipes.isEmpty) {
      return EmptyStateWidget(
        onScanFood: () {
          Navigator.pushNamed(context, '/camera-scan-screen');
        },
      );
    }

    final scanBasedRecipes =
        _filteredRecipes.where((r) => r['basedOnScan'] == true).toList();
    final otherRecipes =
        _filteredRecipes.where((r) => r['basedOnScan'] != true).toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Scan-based suggestions
        if (scanBasedRecipes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lightbulb',
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Based on your recent scan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recipe = scanBasedRecipes[index];
                  return RecipeCardWidget(
                    recipe: recipe,
                    onTap: () => _navigateToRecipeDetail(recipe),
                    onLongPress: () => _showRecipeActions(recipe),
                  );
                },
                childCount: scanBasedRecipes.length,
              ),
            ),
          ),
        ],

        // All recipes
        if (otherRecipes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
              child: Text(
                'All Recipes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recipe = otherRecipes[index];
                  return RecipeCardWidget(
                    recipe: recipe,
                    onTap: () => _navigateToRecipeDetail(recipe),
                    onLongPress: () => _showRecipeActions(recipe),
                  );
                },
                childCount: otherRecipes.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Recipes',
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: _showFavorites ? 'favorite' : 'favorite_border',
              size: 24,
              color: _showFavorites
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showFavorites = !_showFavorites;
                _filterRecipes();
              });
            },
            tooltip: 'Favorites',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: Column(
          children: [
            SizedBox(height: 2.h),

            // Search Bar
            SearchBarWidget(
              controller: _searchController,
              onChanged: (value) {
                _filterRecipes();
              },
              onVoiceSearch: _handleVoiceSearch,
              onFilterTap: _showFilterBottomSheet,
              hasActiveFilters: _selectedFilters.isNotEmpty,
            ),

            SizedBox(height: 2.h),

            // Filter Chips
            FilterChipsWidget(
              activeFilters: _getActiveFiltersList(),
              onRemoveFilter: (filter) {
                setState(() {
                  _selectedFilters.removeWhere((key, value) => value == filter);
                  _filterRecipes();
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedFilters.clear();
                  _filterRecipes();
                });
              },
            ),

            if (_getActiveFiltersList().isNotEmpty) SizedBox(height: 1.h),

            // Recipe Grid
            Expanded(
              child: _isRefreshing
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _buildRecipeGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/recipe-suggestions-screen',
        onNavigate: (route) {
          if (route != '/recipe-suggestions-screen') {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
