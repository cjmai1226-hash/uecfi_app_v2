import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Google Play Console Material 3 Theme System
/// Based on Google Play Console design language (Enterprise Material 3):
/// - Primary: Signature Google Play Blue (#0B57D0) / Dark (#A8C7FA)
/// - Primary Container / Active Pill: Light Blue (#D3E3FD) with Navy (#041E49)
/// - Surface & Cards: Flat crisp surfaces with 1px border (#E0E2EC / #44474E)
/// - Canvas Background: Clean cool tint (#F8FAFD / #111318)
/// - Status Badges: Production Green (#146C2E), In-Review Amber (#B06000), Alert Red (#B3261E)
class AppTheme {
  static bool isDark = false;

  // Google Play Console Brand Colors
  static const Color playBlue = Color(0xFF0B57D0);
  static const Color playDarkBlue = Color(0xFFA8C7FA);
  static const Color playPrimaryContainer = Color(0xFFD3E3FD);
  static const Color playOnPrimaryContainer = Color(0xFF041E49);

  static const Color playSecondary = Color(0xFF00639B);
  static const Color playDarkSecondary = Color(0xFF7FCFFF);
  static const Color playSecondaryContainer = Color(0xFFC2E7FF);
  static const Color playOnSecondaryContainer = Color(0xFF001D32);

  // Play Console Status Badges
  static const Color statusSuccess = Color(0xFF146C2E);
  static const Color statusSuccessContainer = Color(0xFFC4EED0);
  static const Color statusSuccessText = Color(0xFF072711);

  static const Color statusWarning = Color(0xFFB06000);
  static const Color statusWarningContainer = Color(0xFFFEEBD8);
  static const Color statusWarningText = Color(0xFF4A2800);

  static const Color statusError = Color(0xFFB3261E);
  static const Color statusErrorContainer = Color(0xFFF9DEDC);
  static const Color statusErrorText = Color(0xFF410E0B);

  static const Color statusInfo = Color(0xFF00639B);
  static const Color statusInfoContainer = Color(0xFFC2E7FF);
  static const Color statusInfoText = Color(0xFF001D32);

  // Surfaces & Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color containerLight = Color(0xFFF0F4F9);
  static const Color borderLight = Color(0xFFE0E2EC);
  static const Color textLight = Color(0xFF1F1F1F);
  static const Color textSecondaryLight = Color(0xFF444746);

  static const Color backgroundDark = Color(0xFF111318);
  static const Color surfaceDark = Color(0xFF1E1F20);
  static const Color containerDark = Color(0xFF282A2F);
  static const Color borderDark = Color(0xFF44474E);
  static const Color textDark = Color(0xFFE2E2E6);
  static const Color textSecondaryDark = Color(0xFFC4C7C5);

  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  static ThemeData getLightTheme() {
    const primary = playBlue;
    const secondary = playSecondary;
    const tertiary = statusSuccess;
    const errorColor = statusError;

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: surfaceLight,
      dividerColor: borderLight,
      hintColor: textSecondaryLight,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: playPrimaryContainer,
        onPrimaryContainer: playOnPrimaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: playSecondaryContainer,
        onSecondaryContainer: playOnSecondaryContainer,
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: statusSuccessContainer,
        onTertiaryContainer: statusSuccessText,
        error: errorColor,
        onError: Colors.white,
        errorContainer: statusErrorContainer,
        onErrorContainer: statusErrorText,
        surface: surfaceLight,
        onSurface: textLight,
        onSurfaceVariant: textSecondaryLight,
        outline: Color(0xFF74777F),
        outlineVariant: borderLight,
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF8FAFD),
        surfaceContainer: containerLight,
        surfaceContainerHigh: Color(0xFFE9EEF6),
        surfaceContainerHighest: Color(0xFFE1E7F0),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textLight, size: 22),
        actionsIconTheme: const IconThemeData(color: textLight, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textSecondaryLight,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderLight,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: playPrimaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: playOnPrimaryContainer,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: playOnPrimaryContainer, size: 24);
          }
          return const IconThemeData(color: textSecondaryLight, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFF74777F), width: 1.0),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: playPrimaryContainer,
        foregroundColor: playOnPrimaryContainer,
        elevation: 1,
        focusElevation: 2,
        hoverElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: playPrimaryContainer,
        disabledColor: containerLight,
        deleteIconColor: textSecondaryLight,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: playOnPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        modalBackgroundColor: surfaceLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1.0,
        space: 1.0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF303030),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: playDarkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textLight, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          displayMedium: TextStyle(color: textLight, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          titleLarge: TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: textSecondaryLight, fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textLight, fontSize: 15, height: 1.5),
          bodyMedium: TextStyle(color: textLight, fontSize: 14, height: 1.45),
          bodySmall: TextStyle(color: textSecondaryLight, fontSize: 12, height: 1.4),
          labelLarge: TextStyle(color: textLight, fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: textSecondaryLight, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: containerLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    const darkPrimary = playDarkBlue;
    const darkSecondary = playDarkSecondary;
    const darkTertiary = Color(0xFF6DD58C);
    const darkError = Color(0xFFF2B8B5);

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: surfaceDark,
      dividerColor: borderDark,
      hintColor: textSecondaryDark,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Color(0xFF042F73),
        primaryContainer: Color(0xFF0842A0),
        onPrimaryContainer: playPrimaryContainer,
        secondary: darkSecondary,
        onSecondary: Color(0xFF003454),
        secondaryContainer: Color(0xFF004A77),
        onSecondaryContainer: Color(0xFFC2E7FF),
        tertiary: darkTertiary,
        onTertiary: Color(0xFF003914),
        tertiaryContainer: Color(0xFF005322),
        onTertiaryContainer: Color(0xFFC4EED0),
        error: darkError,
        onError: Color(0xFF601410),
        errorContainer: Color(0xFF8C1D18),
        onErrorContainer: Color(0xFFF9DEDC),
        surface: surfaceDark,
        onSurface: textDark,
        onSurfaceVariant: textSecondaryDark,
        outline: Color(0xFF8E918F),
        outlineVariant: borderDark,
        surfaceContainerLowest: Color(0xFF0C0E12),
        surfaceContainerLow: Color(0xFF191B20),
        surfaceContainer: containerDark,
        surfaceContainerHigh: Color(0xFF33353B),
        surfaceContainerHighest: Color(0xFF3D4046),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textDark, size: 22),
        actionsIconTheme: const IconThemeData(color: textDark, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: darkPrimary,
        labelColor: darkPrimary,
        unselectedLabelColor: textSecondaryDark,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderDark,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1.0),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: const Color(0xFF004A77),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: playPrimaryContainer,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: playPrimaryContainer, size: 24);
          }
          return const IconThemeData(color: textSecondaryDark, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF042F73),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF042F73),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: Color(0xFF8E918F), width: 1.0),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF004A77),
        foregroundColor: playPrimaryContainer,
        elevation: 1,
        focusElevation: 2,
        hoverElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: const Color(0xFF004A77),
        disabledColor: containerDark,
        deleteIconColor: textSecondaryDark,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: playPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderDark, width: 1.0),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderDark, width: 1.0),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1.0,
        space: 1.0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE2E2E6),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF1F1F1F),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: playBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textDark, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          displayMedium: TextStyle(color: textDark, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          titleLarge: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textDark, fontSize: 15, height: 1.5),
          bodyMedium: TextStyle(color: textDark, fontSize: 14, height: 1.45),
          bodySmall: TextStyle(color: textSecondaryDark, fontSize: 12, height: 1.4),
          labelLarge: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: textSecondaryDark, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: containerDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2.0),
        ),
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get contentColor =>
      isDarkMode ? AppTheme.textDark : AppTheme.textLight;

  Color get secondaryContentColor =>
      isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

  Color get cardBorderColor =>
      isDarkMode ? AppTheme.borderDark : AppTheme.borderLight;

  Color get surfaceContainerColor =>
      isDarkMode ? AppTheme.containerDark : AppTheme.containerLight;

  Color get primaryContainerColor =>
      isDarkMode ? const Color(0xFF0842A0) : AppTheme.playPrimaryContainer;

  Color get onPrimaryContainerColor =>
      isDarkMode ? AppTheme.playPrimaryContainer : AppTheme.playOnPrimaryContainer;
}
