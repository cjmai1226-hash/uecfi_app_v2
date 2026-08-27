import 'package:flutter/material.dart';

class AppTheme {
  static bool isDark = false;

  // App brand colors: Inspired by Facebook (Facebook Blue & Status Green)
  static Color get primaryColor => isDark ? const Color(0xFF1877F2) : const Color(0xFF1877F2);
  static Color get secondaryColor => isDark ? const Color(0xFF45BD62) : const Color(0xFF00A400);
  static Color get backgroundColor => isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
  static Color get cardColor => isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
  static Color get textColor => isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  static Color get textSecondaryColor => isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
  static Color get borderLightColor => isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);

  static ThemeData get lightTheme {
    const primary = Color(0xFF1877F2); // Facebook Blue
    const secondary = Color(0xFF00A400); // Facebook Status Green
    const background = Color(0xFFF0F2F5); // Light Gray Background
    const card = Color(0xFFFFFFFF);
    const text = Color(0xFF050505); // High Contrast Text
    const textSecondary = Color(0xFF65676B); // Medium Gray Text
    const borderLight = Color(0xFFE4E6EB); // Soft Grey Border

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: borderLight,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: Color(0xFFF02849), // Facebook Danger Red
        onError: Colors.white,
        surface: card,
        onSurface: text,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0, // Flat elevation typical of Facebook cards
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Clean modern 12px corners
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.1),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 26);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Polished Facebook-style corners
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: text, fontSize: 32, fontWeight: FontWeight.w600),
        displayMedium: TextStyle(color: text, fontSize: 26, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE4E6EB), // Slightly darker grey input fill for contrast
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // Circular/oval inputs for modern FB look
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF1877F2); // Facebook Dark Mode Blue
    const darkSecondary = Color(0xFF45BD62); // Green status active
    const darkBackground = Color(0xFF18191A); // Facebook Dark Mode dark grey
    const darkCard = Color(0xFF242526); // Facebook Dark Mode card grey
    const darkText = Color(0xFFE4E6EB); // High contrast light gray text
    const darkTextSecondary = Color(0xFFB0B3B8); // Medium light gray text
    const darkBorder = Color(0xFF3E4042); // Dark dividers/borders

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: darkBorder,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkSecondary,
        onSecondary: Colors.white,
        error: Color(0xFFF02849),
        onError: Colors.white,
        surface: darkCard,
        onSurface: darkText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: darkPrimary,
        labelColor: darkPrimary,
        unselectedLabelColor: darkTextSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: darkBorder,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: darkPrimary.withValues(alpha: 0.15),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 26);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkText, fontSize: 32, fontWeight: FontWeight.w600),
        displayMedium: TextStyle(color: darkText, fontSize: 26, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: darkText, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: darkText, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A3B3C), // Dark grey input fill
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
      ),
    );
  }
}
