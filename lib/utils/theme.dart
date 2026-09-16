import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

enum AppThemeColor {
  electricViolet,
  googleAI,
}

class AppTheme {
  static bool isDark = false;

  static ThemeData get lightTheme =>
      getLightTheme(ThemeService.instance.themeColor);

  static ThemeData get darkTheme =>
      getDarkTheme(ThemeService.instance.themeColor);

  static ThemeData getLightTheme([AppThemeColor colorTheme = AppThemeColor.electricViolet]) {
    final Color primary;
    final Color secondary;
    final Color background;
    final Color card;
    final Color text;
    final Color textSecondary;
    final Color borderLight;
    final Color errorColor;

    switch (colorTheme) {
      case AppThemeColor.googleAI:
        primary = const Color(0xFF1A73E8); // Google AI Royal Blue
        secondary = const Color(0xFF7C3AED); // Gemini AI Violet
        background = const Color(0xFFF8F9FA); // Google Cloud Light
        card = const Color(0xFFFFFFFF);
        text = const Color(0xFF1F1F1F);
        textSecondary = const Color(0xFF5F6368);
        borderLight = const Color(0xFFE8EAED);
        errorColor = const Color(0xFFEA4335);
        break;
      case AppThemeColor.electricViolet:
        primary = const Color(0xFFA100FF); // Accenture Electric Violet
        secondary = const Color(0xFF7500C0); // Deep Violet Accent
        background = const Color(0xFFF7F7FA); // Architectural Studio Light Gray
        card = const Color(0xFFFFFFFF);
        text = const Color(0xFF0E0E14); // Ultra-crisp Onyx Text
        textSecondary = const Color(0xFF6E6E82); // Refined Slate Gray Text
        borderLight = const Color(0xFFE5E5ED); // Crisp High-Tech Border
        errorColor = const Color(0xFFFF2A55);
        break;
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: borderLight,
      
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: card,
        onSurface: text,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderLight,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 15),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderLight, width: 1.2),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 6,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 26);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: text, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: text, fontSize: 26, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.45),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEEEF4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme([AppThemeColor colorTheme = AppThemeColor.electricViolet]) {
    final Color darkPrimary;
    final Color darkSecondary;
    final Color darkBackground;
    final Color darkCard;
    final Color darkText;
    final Color darkTextSecondary;
    final Color darkBorder;
    final Color darkError;

    switch (colorTheme) {
      case AppThemeColor.googleAI:
        darkPrimary = const Color(0xFF4285F4); // Google AI Vibrant Blue
        darkSecondary = const Color(0xFF9334E6); // Gemini AI Sparkle Purple
        darkBackground = const Color(0xFF131314); // Google Gemini Dark Obsidian
        darkCard = const Color(0xFF1E1F20); // Google Gemini Card Surface
        darkText = const Color(0xFFE3E3E3); // Google Titanium White
        darkTextSecondary = const Color(0xFF9AA0A6); // Google Cool Slate
        darkBorder = const Color(0xFF333538); // Google Precision Dark Border
        darkError = const Color(0xFFF28B82);
        break;
      case AppThemeColor.electricViolet:
        darkPrimary = const Color(0xFFA100FF); // Accenture Electric Violet
        darkSecondary = const Color(0xFF00E5FF); // Cyber Cyan Accent
        darkBackground = const Color(0xFF0D0D12); // Deep Obsidian Dark Mode
        darkCard = const Color(0xFF16161F); // Dark Graphite Slate Card
        darkText = const Color(0xFFF5F5FA); // High Contrast Pristine Text
        darkTextSecondary = const Color(0xFF9E9EAF); // Purple-Tinted Gray Text
        darkBorder = const Color(0xFF262633); // Subtle Precision Border
        darkError = const Color(0xFFFF2A55);
        break;
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: darkBorder,
      
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkSecondary,
        onSecondary: Colors.white,
        error: darkError,
        onError: Colors.white,
        surface: darkCard,
        onSurface: darkText,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: darkPrimary,
        labelColor: darkPrimary,
        unselectedLabelColor: darkTextSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: darkBorder,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 15),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBorder, width: 1.2),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: darkPrimary.withValues(alpha: 0.18),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkPrimary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: darkPrimary, size: 26);
          }
          return IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: BorderSide(color: darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: darkText, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: darkText, fontSize: 26, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: darkText, fontSize: 17, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: darkText, fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(color: darkText, fontSize: 14, height: 1.45),
          bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkPrimary, width: 2),
        ),
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get contentColor => isDarkMode
      ? const Color(0xFFF5F5FA)
      : const Color(0xFF0E0E14);

  Color get secondaryContentColor => isDarkMode
      ? const Color(0xFFA0A0AB)
      : const Color(0xFF6E6E82);
}

