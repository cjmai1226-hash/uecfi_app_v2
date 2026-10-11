import 'package:flutter/material.dart';

/// Isolated styling and color palettes specifically crafted for the UECFI History & Heritage section.
/// All colors, gradients, card themes, and typography helpers for this section are kept strictly here.
class HistoryStyles {
  // Prevent instantiation
  HistoryStyles._();

  // --- TOPIC PALETTES ---
  // 1. Sunset Amber (Origins & Foundations)
  static const Color amberPrimary = Color(0xFFFF7A00);
  static const Color amberSecondary = Color(0xFFFF9E40);
  static const Color amberDark = Color(0xFFC75D00);
  static const List<Color> amberGradient = [
    Color(0xFFFF7A00),
    Color(0xFFFF9E40),
  ];

  // 2. Celestial Azure (Spirit & Doctrine)
  static const Color azurePrimary = Color(0xFF0072FF);
  static const Color azureSecondary = Color(0xFF00C6FF);
  static const Color azureDark = Color(0xFF004CB5);
  static const List<Color> azureGradient = [
    Color(0xFF0052D4),
    Color(0xFF4364F7),
    Color(0xFF6FB1FC),
  ];

  // 3. Royal Violet (Pioneers & Leaders)
  static const Color violetPrimary = Color(0xFF8A2387);
  static const Color violetSecondary = Color(0xFFE94057);
  static const Color violetAccent = Color(0xFF9D4EDD);
  static const List<Color> violetGradient = [
    Color(0xFF8A2387),
    Color(0xFFE94057),
    Color(0xFFF27121),
  ];

  // 4. Emerald Mint (Service, Charity & Healing)
  static const Color emeraldPrimary = Color(0xFF00B09B);
  static const Color emeraldSecondary = Color(0xFF96C93D);
  static const Color emeraldDark = Color(0xFF007A6C);
  static const List<Color> emeraldGradient = [
    Color(0xFF0BA360),
    Color(0xFF3CBA92),
  ];

  // 5. Golden Flame (The Sacred Motto & Seal)
  static const Color goldPrimary = Color(0xFFF7971E);
  static const Color goldSecondary = Color(0xFFFFD200);
  static const List<Color> goldGradient = [
    Color(0xFFF7971E),
    Color(0xFFFFD200),
  ];

  // 6. Cyber Ruby / Crimson (Struggle for Freedom & Revolution)
  static const Color rubyPrimary = Color(0xFFED213A);
  static const Color rubySecondary = Color(0xFF93291E);
  static const List<Color> rubyGradient = [
    Color(0xFFED213A),
    Color(0xFF93291E),
  ];

  // --- DYNAMIC THEMING HELPERS ---
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardBackground(BuildContext context) {
    return isDark(context) ? const Color(0xFF1B1B26) : Colors.white;
  }

  static Color subtleBackground(BuildContext context) {
    return isDark(context) ? const Color(0xFF14141E) : const Color(0xFFF5F6FA);
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? const Color(0xFFF5F5FA) : const Color(0xFF14142B);
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? const Color(0xFFA2A2B5) : const Color(0xFF6E6E82);
  }

  static Color borderColor(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF2E2E42)
        : const Color(0xFFE6E7F0);
  }

  // --- CARD DECORATION BUILDERS ---
  static BoxDecoration cardDecoration({
    required BuildContext context,
    required List<Color> gradientColors,
    double borderRadius = 20,
  }) {
    final dark = isDark(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [
                gradientColors.first.withValues(alpha: 0.22),
                gradientColors.last.withValues(alpha: 0.12),
              ]
            : [
                gradientColors.first.withValues(alpha: 0.10),
                gradientColors.last.withValues(alpha: 0.04),
              ],
      ),
      border: Border.all(
        color: gradientColors.first.withValues(alpha: dark ? 0.40 : 0.30),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withValues(alpha: dark ? 0.16 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration badgeDecoration({
    required List<Color> gradientColors,
    double radius = 12,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration pillDecoration({
    required BuildContext context,
    Color? color,
  }) {
    final dark = isDark(context);
    final accent = color ?? (dark ? Colors.white : Colors.black);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: accent.withValues(alpha: dark ? 0.15 : 0.09),
      border: Border.all(
        color: accent.withValues(alpha: dark ? 0.28 : 0.18),
        width: 1,
      ),
    );
  }
}
