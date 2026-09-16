import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('About'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/image.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Version Pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3B3C)
                      : const Color(0xFFE4E6EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Version 2.1.0',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: context.contentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // The App Text (Unwrapped)
            Text(
              'The App',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UECFI APP is the official mobile companion for members of the Union Espiritista Cristiana de Filipinas, Inc. (UECFI). It provides digital access to the Ilocano Bible, church hymns, local prayer guides, and directory maps of worship centers, encouraging connection and faith.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontSize: 14.5,
                color: context.contentColor,
              ),
            ),
            const SizedBox(height: 28),

            // The Team Text (Unwrapped)
            Row(
              children: [
                Image.asset(
                  'assets/images/brand_mark.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'We are devchristian, the engineering and design team behind UECFI APP. Our mission is to combine technical precision and modern visual aesthetics to deliver state-of-the-art software solutions that uplift users and build community.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontSize: 14.5,
                color: context.contentColor,
              ),
            ),

            const SizedBox(height: 48),

            // Copyright statement
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 Union Espiritista Cristiana de Filipinas, Inc.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.secondaryContentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.secondaryContentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
