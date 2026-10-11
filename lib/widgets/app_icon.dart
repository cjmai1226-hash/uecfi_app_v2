import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

// Automatically export hugeicons so any screen importing app_icon.dart
// can seamlessly access icon definitions (e.g. HugeIcons.strokeRoundedHome01).
export 'package:hugeicons/hugeicons.dart';

/// A reusable icon component that encapsulates [HugeIcon] with a default
/// [strokeWidth] of 2.0, contextual theme-aware coloring, and size customization.
class AppIcon extends StatelessWidget {
  /// The icon definition (typically from [HugeIcons]).
  final List<List<dynamic>> icon;

  /// The size of the icon in logical pixels. Defaults to `24.0`.
  final double size;

  /// The primary color of the icon.
  ///
  /// When not provided, this falls back contextually to the enclosing [IconTheme],
  /// or to [ColorScheme.onSurface] from the current [Theme].
  final Color? color;

  /// The secondary color for duotone/twotone icons.
  final Color? secondaryColor;

  /// The stroke width for stroke-based icons. Defaults to `2.0`.
  final double strokeWidth;

  /// Whether to render the secondary layer at full opacity instead of the
  /// reduced opacity baked into duotone icon data.
  final bool disableSecondaryOpacity;

  const AppIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
    this.disableSecondaryOpacity = false,
  });

  /// Convenient constructor for small icons (18px) with 2.0 stroke width.
  const AppIcon.small({
    super.key,
    required this.icon,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
    this.disableSecondaryOpacity = false,
  }) : size = 18.0;

  /// Convenient constructor for medium/standard icons (24px) with 2.0 stroke width.
  const AppIcon.medium({
    super.key,
    required this.icon,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
    this.disableSecondaryOpacity = false,
  }) : size = 24.0;

  /// Convenient constructor for large icons (32px) with 2.0 stroke width.
  const AppIcon.large({
    super.key,
    required this.icon,
    this.color,
    this.secondaryColor,
    this.strokeWidth = 2.0,
    this.disableSecondaryOpacity = false,
  }) : size = 32.0;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;

    return HugeIcon(
      icon: icon,
      size: size,
      color: effectiveColor,
      secondaryColor: secondaryColor,
      strokeWidth: strokeWidth,
      disableSecondaryOpacity: disableSecondaryOpacity,
    );
  }
}
