import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class AddIngredientModalWidget extends StatefulWidget {
  final Function(String) onAddIngredient;

  const AddIngredientModalWidget({super.key, required this.onAddIngredient});

  @override
  State<AddIngredientModalWidget> createState() =>
      _AddIngredientModalWidgetState();
}

class _AddIngredientModalWidgetState extends State<AddIngredientModalWidget> {
  final TextEditingController _ingredientController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty) {
      widget.onAddIngredient(ingredient);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 6.w,
        right: 6.w,
        top: 4.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 4.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Ingredient',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _ingredientController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Ingredient name',
              hintText: 'e.g., Tomatoes, Onions, Chicken',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'restaurant',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _addIngredient(),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addIngredient,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
