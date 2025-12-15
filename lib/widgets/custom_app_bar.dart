import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with large title (iOS style)
  large,

  /// Transparent app bar for overlays
  transparent,

  /// App bar with progress indicator
  progress,
}

/// Custom app bar widget for nutrition tracking app
///
/// Features:
/// - Multiple variants (standard, search, large, transparent, progress)
/// - Consistent dark theme styling
/// - Optional leading/trailing actions
/// - Search functionality with animation
/// - Progress indicator support
/// - Haptic feedback on interactions
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// App bar variant
  final CustomAppBarVariant variant;

  /// Title text
  final String? title;

  /// Custom title widget (overrides title text)
  final Widget? titleWidget;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// Action widgets displayed on the right
  final List<Widget>? actions;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Search hint text (for search variant)
  final String? searchHint;

  /// Search callback (for search variant)
  final Function(String)? onSearch;

  /// Search controller (for search variant)
  final TextEditingController? searchController;

  /// Progress value (0.0 to 1.0, for progress variant)
  final double? progress;

  /// Custom elevation
  final double? elevation;

  /// Background color override
  final Color? backgroundColor;

  /// Whether to center the title
  final bool centerTitle;

  /// Custom height
  final double? height;

  const CustomAppBar({
    super.key,
    this.variant = CustomAppBarVariant.standard,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.searchHint,
    this.onSearch,
    this.searchController,
    this.progress,
    this.elevation,
    this.backgroundColor,
    this.centerTitle = false,
    this.height,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize {
    double appBarHeight = height ?? kToolbarHeight;
    if (variant == CustomAppBarVariant.large) {
      appBarHeight = 96;
    }
    return Size.fromHeight(appBarHeight);
  }
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _searchAnimationController;
  // ignore: unused_field
  late Animation<double> _searchAnimation;
  bool _isSearchActive = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (_isSearchActive) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        if (widget.onSearch != null) {
          widget.onSearch!('');
        }
      }
    });
  }

  Widget _buildStandardAppBar(ThemeData theme) {
    return AppBar(
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      title: widget.titleWidget ??
          (widget.title != null
              ? Text(
                  widget.title!,
                  style: theme.appBarTheme.titleTextStyle,
                )
              : null),
      centerTitle: widget.centerTitle,
      actions: widget.actions,
      elevation: widget.elevation ?? theme.appBarTheme.elevation,
      backgroundColor:
          widget.backgroundColor ?? theme.appBarTheme.backgroundColor,
    );
  }

  Widget _buildSearchAppBar(ThemeData theme) {
    return AppBar(
      leading: _isSearchActive
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _toggleSearch,
              tooltip: 'Close search',
            )
          : widget.leading,
      automaticallyImplyLeading:
          !_isSearchActive && widget.automaticallyImplyLeading,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Search...',
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: widget.onSearch,
              )
            : widget.titleWidget ??
                (widget.title != null
                    ? Text(
                        widget.title!,
                        style: theme.appBarTheme.titleTextStyle,
                      )
                    : null),
      ),
      centerTitle: widget.centerTitle,
      actions: [
        if (!_isSearchActive)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search',
          ),
        if (_isSearchActive && _searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              HapticFeedback.lightImpact();
              _searchController.clear();
              if (widget.onSearch != null) {
                widget.onSearch!('');
              }
            },
            tooltip: 'Clear',
          ),
        if (!_isSearchActive) ...(widget.actions ?? []),
      ],
      elevation: widget.elevation ?? theme.appBarTheme.elevation,
      backgroundColor:
          widget.backgroundColor ?? theme.appBarTheme.backgroundColor,
    );
  }

  Widget _buildLargeAppBar(ThemeData theme) {
    return SliverAppBar(
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      expandedHeight: 96,
      floating: false,
      pinned: true,
      elevation: widget.elevation ?? theme.appBarTheme.elevation,
      backgroundColor:
          widget.backgroundColor ?? theme.appBarTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: widget.titleWidget ??
            (widget.title != null
                ? Text(
                    widget.title!,
                    style: theme.appBarTheme.titleTextStyle
                        ?.copyWith(fontSize: 28),
                  )
                : null),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: widget.actions,
    );
  }

  Widget _buildTransparentAppBar(ThemeData theme) {
    return AppBar(
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      title: widget.titleWidget ??
          (widget.title != null
              ? Text(
                  widget.title!,
                  style: theme.appBarTheme.titleTextStyle,
                )
              : null),
      centerTitle: widget.centerTitle,
      actions: widget.actions,
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildProgressAppBar(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: widget.titleWidget ??
              (widget.title != null
                  ? Text(
                      widget.title!,
                      style: theme.appBarTheme.titleTextStyle,
                    )
                  : null),
          centerTitle: widget.centerTitle,
          actions: widget.actions,
          elevation: 0,
          backgroundColor:
              widget.backgroundColor ?? theme.appBarTheme.backgroundColor,
        ),
        if (widget.progress != null)
          LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: theme.colorScheme.surface,
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 2,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.variant) {
      case CustomAppBarVariant.standard:
        return _buildStandardAppBar(theme);
      case CustomAppBarVariant.search:
        return _buildSearchAppBar(theme);
      case CustomAppBarVariant.large:
        return _buildLargeAppBar(theme);
      case CustomAppBarVariant.transparent:
        return _buildTransparentAppBar(theme);
      case CustomAppBarVariant.progress:
        return _buildProgressAppBar(theme);
    }
  }
}
