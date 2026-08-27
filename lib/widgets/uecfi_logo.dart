import 'package:flutter/material.dart';

class UecfiLogo extends StatelessWidget {
  final double size;
  final double fontSize;

  const UecfiLogo({super.key, this.size = 36, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'espiritista',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: isDark ? Colors.white : const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}
