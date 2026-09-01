import 'package:flutter/material.dart';

class UecfiLogo extends StatelessWidget {
  final double size;
  final double fontSize;
  final bool showBrandMark;

  const UecfiLogo({
    super.key,
    this.size = 26,
    this.fontSize = 20,
    this.showBrandMark = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBrandMark) ...[
          ClipOval(
            child: Image.asset(
              'assets/images/brand_mark.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          'espiritista',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}
