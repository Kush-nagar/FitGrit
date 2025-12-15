import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class that contains all theme configurations for the nutrition tracking application.
class AppTheme {
  AppTheme._();

  // Primary Colors
  static const Color primaryLime = Color.fromRGBO(69, 197, 136, 1.0);
  static const Color primaryLimeVariant = Color.fromRGBO(69, 197, 136, 1.0);

  // Background Colors
  static const Color backgroundDark = Color(0xFF1C1C1C);
  static const Color surfaceDark = Color(0xFF2E2E2E);
  static const Color cardDark = Color(0xFF2E2E2E);
  static const Color dialogDark = Color(0xFF2E2E2E);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888F92);
  static const Color textTertiary = Color(0xFF5E6468);

  // Accent Colors
  static const Color accentPurple = Color(0xFF6A6AED);
  static const Color accentRed = Color(0xFFD73767);
  static const Color accentOrange = Color(0xFFFF7F3F);
  static const Color accentBlue = Color.fromARGB(255, 3, 222, 238);

  // Border and Divider
  static const Color borderColor = Color(0xFF3D4040);
  static const Color dividerDark = Color(0xFF3D4040);

  // Shadow Colors
  static const Color shadowDark = Color(0x33000000);

  // Light theme colors (minimal support for system light mode)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF1C1C1C);

  /// Dark theme (primary theme for the app)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryLime,
      onPrimary: backgroundDark,
      primaryContainer: primaryLimeVariant,
      onPrimaryContainer: backgroundDark,
      secondary: accentPurple,
      onSecondary: textPrimary,
      secondaryContainer: accentPurple,
      onSecondaryContainer: textPrimary,
      tertiary: accentBlue,
      onTertiary: backgroundDark,
      tertiaryContainer: accentBlue,
      onTertiaryContainer: backgroundDark,
      error: accentRed,
      onError: textPrimary,
      surface: surfaceDark,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: borderColor,
      outlineVariant: dividerDark,
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: textLight,
      inversePrimary: primaryLimeVariant,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 2.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryLime,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 4.0,
      selectedIconTheme: IconThemeData(size: 28),
      unselectedIconTheme: IconThemeData(size: 24),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryLime,
      foregroundColor: backgroundDark,
      elevation: 4.0,
      shape: CircleBorder(),
      iconSize: 28,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: backgroundDark,
        backgroundColor: primaryLime,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLime,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: primaryLime, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLime,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Theme
    textTheme: _buildTextTheme(isLight: false),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryLime, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: accentRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: accentRed, width: 2),
      ),
      labelStyle: GoogleFonts.lato(
        color: textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.lato(
        color: textTertiary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.lato(
        color: accentRed,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLime;
        }
        return textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLime.withValues(alpha: 0.5);
        }
        return textTertiary.withValues(alpha: 0.3);
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLime;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(backgroundDark),
      side: const BorderSide(color: borderColor, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLime;
        }
        return textSecondary;
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryLime,
      linearTrackColor: surfaceDark,
      circularTrackColor: surfaceDark,
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLime,
      thumbColor: primaryLime,
      overlayColor: primaryLime.withValues(alpha: 0.2),
      inactiveTrackColor: surfaceDark,
      trackHeight: 4.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: primaryLime,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryLime,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.lato(
        color: backgroundDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDark,
      contentTextStyle: GoogleFonts.lato(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: primaryLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4.0,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: dividerDark,
      thickness: 1,
      space: 1,
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceDark,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: dialogDark,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      contentTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      tileColor: surfaceDark,
      selectedTileColor: primaryLime.withValues(alpha: 0.1),
      iconColor: textSecondary,
      textColor: textPrimary,
      titleTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      subtitleTextStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),
  );

  /// Light theme (minimal support)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLime,
      onPrimary: backgroundDark,
      primaryContainer: primaryLimeVariant,
      onPrimaryContainer: backgroundDark,
      secondary: accentPurple,
      onSecondary: textPrimary,
      secondaryContainer: accentPurple,
      onSecondaryContainer: textPrimary,
      tertiary: accentBlue,
      onTertiary: backgroundDark,
      tertiaryContainer: accentBlue,
      onTertiaryContainer: backgroundDark,
      error: accentRed,
      onError: textPrimary,
      surface: surfaceLight,
      onSurface: textLight,
      onSurfaceVariant: textSecondary,
      outline: borderColor,
      outlineVariant: dividerDark,
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceDark,
      onInverseSurface: textPrimary,
      inversePrimary: primaryLime,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: surfaceLight,
    dividerColor: dividerDark,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: textLight,
        size: 24,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 2.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLime,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 4.0,
      selectedIconTheme: IconThemeData(size: 28),
      unselectedIconTheme: IconThemeData(size: 24),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: backgroundDark,
        backgroundColor: primaryLime,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      fillColor: backgroundLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryLime, width: 2),
      ),
      labelStyle: GoogleFonts.lato(
        color: textLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.lato(
        color: textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLight,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
      contentTextStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),

    textTheme: _buildTextTheme(isLight: true),
  );

  /// Helper method to build text theme based on brightness
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHigh = isLight ? textLight : textPrimary;
    final Color textMedium =
        isLight ? textLight.withValues(alpha: 0.7) : textSecondary;
    final Color textLow =
        isLight ? textLight.withValues(alpha: 0.5) : textTertiary;

    return TextTheme(
      // Display styles (large headings)
      displayLarge: GoogleFonts.lato(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        color: textHigh,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.lato(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textHigh,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.lato(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textHigh,
        letterSpacing: 0,
      ),

      // Headline styles (section headings)
      headlineLarge: GoogleFonts.lato(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textHigh,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.lato(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textHigh,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.lato(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textHigh,
        letterSpacing: 0,
      ),

      // Title styles (card titles, list headers)
      titleLarge: GoogleFonts.lato(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textHigh,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textHigh,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textHigh,
        letterSpacing: 0.1,
      ),

      // Body styles (main content)
      bodyLarge: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHigh,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textHigh,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMedium,
        letterSpacing: 0.4,
      ),

      // Label styles (buttons, captions)
      labelLarge: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textHigh,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMedium,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.lato(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textLow,
        letterSpacing: 0.5,
      ),
    );
  }
}
