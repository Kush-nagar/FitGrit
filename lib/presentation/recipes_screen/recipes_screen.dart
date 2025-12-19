import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/config/app_config.dart';
import '../../models/recipe_model.dart';
import '../../services/gemini_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/recipe_card_widget.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  bool _isLoading = true;
  List<Recipe> _recipes = [];
  String? _errorMessage;
  List<String> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    // Get ingredients from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null || args['ingredients'] == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No ingredients provided';
        });
        return;
      }

      _ingredients = List<String>.from(args['ingredients'] as List<dynamic>);

      if (_ingredients.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No ingredients provided';
        });
        return;
      }

      try {
        // Get Gemini API key from AppConfig
        final apiKey = AppConfig.geminiApiKey;

        if (apiKey.isEmpty) {
          throw Exception(
              'Gemini API key not configured. Please check AppConfig.');
        }

        final geminiService = GeminiService(apiKey: apiKey);
        final recipesData = await geminiService.generateRecipesFromIngredients(
          _ingredients,
          maxRecipes: 8,
        );

        final recipes = recipesData.map((data) {
          return Recipe.fromJson(data);
        }).toList();

        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    });
  }

  Future<void> _refreshRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get Gemini API key from AppConfig
      final apiKey = AppConfig.geminiApiKey;

      if (apiKey.isEmpty) {
        throw Exception(
            'Gemini API key not configured. Please check AppConfig.');
      }

      final geminiService = GeminiService(apiKey: apiKey);
      final recipesData = await geminiService.generateRecipesFromIngredients(
        _ingredients,
        maxRecipes: 8,
      );

      final recipes = recipesData.map((data) {
        return Recipe.fromJson(data);
      }).toList();

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Recipe Suggestions',
        actions: [
          if (!_isLoading && _recipes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshRecipes,
              tooltip: 'Generate new recipes',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRecipesList();
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Generating 8 delicious recipes...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Using ingredients: ${_ingredients.join(", ")}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(3.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Failed to Generate Recipes',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _refreshRecipes,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(3.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Recipes Found',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 1.h),
            Text(
              'We couldn\'t find any recipes for the provided ingredients.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesList() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with ingredient count
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(2.5.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.4),
                theme.colorScheme.tertiaryContainer.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_recipes.length} Delicious Recipes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Using: ${_ingredients.join(", ")}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Recipes list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 2.5.h),
            itemCount: _recipes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 2.5.h),
                child: RecipeCardWidget(
                  recipe: _recipes[index],
                  onTap: () => _showRecipeDetails(_recipes[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    Navigator.pushNamed(
      context,
      '/recipe-details-screen',
      arguments: {'recipe': recipe},
    );
  }
}
