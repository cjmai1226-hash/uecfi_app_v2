import 'dart:math' as math;
import 'package:flutter/material.dart';

class SparklingTrophyIcon extends StatefulWidget {
  final bool isSelected;
  final double size;

  const SparklingTrophyIcon({
    super.key,
    required this.isSelected,
    this.size = 24.0,
  });

  @override
  State<SparklingTrophyIcon> createState() => _SparklingTrophyIconState();
}

class _SparklingTrophyIconState extends State<SparklingTrophyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 5-second total cycle (1.3s sparkle burst + 3.7s idle rest)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.isSelected
        ? theme.tabBarTheme.labelColor ?? theme.colorScheme.primary
        : theme.tabBarTheme.unselectedLabelColor ?? theme.unselectedWidgetColor;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;

          // Sparkle 1: active during 0.0 -> 0.18 of total cycle (0s -> 0.9s)
          double s1Scale = 0.0;
          double s1Opacity = 0.0;
          double s1Progress = 0.0;
          if (t < 0.18) {
            s1Progress = t / 0.18;
            s1Scale = math.sin(s1Progress * math.pi);
            s1Opacity = s1Scale.clamp(0.0, 1.0);
          }

          // Sparkle 2: active during 0.08 -> 0.26 of total cycle (0.4s -> 1.3s)
          double s2Scale = 0.0;
          double s2Opacity = 0.0;
          double s2Progress = 0.0;
          if (t >= 0.08 && t < 0.26) {
            s2Progress = (t - 0.08) / 0.18;
            s2Scale = math.sin(s2Progress * math.pi);
            s2Opacity = s2Scale.clamp(0.0, 1.0);
          }

          return SizedBox(
            width: widget.size + 14,
            height: widget.size + 8,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Main Trophy Icon
                Icon(
                  widget.isSelected
                      ? Icons.emoji_events_rounded
                      : Icons.emoji_events_outlined,
                  size: widget.size,
                  color: widget.isSelected ? Colors.amber.shade600 : iconColor,
                ),

                // Sparkle 1: Top-Right Star
                if (s1Opacity > 0)
                  Positioned(
                    top: 0,
                    right: 1,
                    child: Transform.scale(
                      scale: s1Scale * 0.85,
                      child: Transform.rotate(
                        angle: s1Progress * math.pi * 0.5,
                        child: Opacity(
                          opacity: s1Opacity,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 11,
                            color: widget.isSelected
                                ? Colors.amberAccent
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Sparkle 2: Top-Left Star
                if (s2Opacity > 0)
                  Positioned(
                    top: 3,
                    left: 1,
                    child: Transform.scale(
                      scale: s2Scale * 0.7,
                      child: Transform.rotate(
                        angle: -s2Progress * math.pi * 0.4,
                        child: Opacity(
                          opacity: s2Opacity,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 9,
                            color: widget.isSelected
                                ? Colors.amberAccent.shade100
                                : theme.colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
