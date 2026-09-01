import 'package:flutter/material.dart';

class PostGradientPreset {
  final String id;
  final String name;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  const PostGradientPreset({
    required this.id,
    required this.name,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  Gradient get gradient => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      );

  static const List<PostGradientPreset> presets = [
    PostGradientPreset(
      id: 'default',
      name: 'None',
      colors: [Colors.transparent, Colors.transparent],
    ),
    PostGradientPreset(
      id: 'accenture_signature',
      name: 'Accenture Violet',
      colors: [Color(0xFF460073), Color(0xFFA100FF), Color(0xFFC553FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_magenta',
      name: 'Electric Magenta',
      colors: [Color(0xFF6B00B6), Color(0xFFA100FF), Color(0xFFFF007A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_cyber',
      name: 'Cyber Indigo',
      colors: [Color(0xFF1A003B), Color(0xFF3F00FF), Color(0xFF00D2FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_sunset',
      name: 'Dynamic Horizon',
      colors: [Color(0xFF460073), Color(0xFFD6006E), Color(0xFFFF6A00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_teal',
      name: 'Quantum Teal',
      colors: [Color(0xFF0D0026), Color(0xFF7500C0), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_neon',
      name: 'Neon Pulse',
      colors: [Color(0xFF8000FF), Color(0xFFFF0055)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_carbon',
      name: 'Carbon Velvet',
      colors: [Color(0xFF0D001A), Color(0xFF2E005B), Color(0xFF6A00B8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    PostGradientPreset(
      id: 'accenture_radiant',
      name: 'Radiant Violet',
      colors: [Color(0xFF7500C0), Color(0xFFA100FF), Color(0xFFFFBE3B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static PostGradientPreset? findById(String? id) {
    if (id == null || id.isEmpty || id == 'default') return null;

    // Direct match
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {}

    // Legacy ID fallback mapping
    switch (id) {
      case 'sunset':
        return presets.firstWhere((p) => p.id == 'accenture_sunset');
      case 'ocean':
        return presets.firstWhere((p) => p.id == 'accenture_cyber');
      case 'emerald':
        return presets.firstWhere((p) => p.id == 'accenture_teal');
      case 'royal':
        return presets.firstWhere((p) => p.id == 'accenture_signature');
      case 'golden':
        return presets.firstWhere((p) => p.id == 'accenture_radiant');
      case 'midnight':
        return presets.firstWhere((p) => p.id == 'accenture_carbon');
      case 'crimson':
        return presets.firstWhere((p) => p.id == 'accenture_neon');
      case 'lavender':
        return presets.firstWhere((p) => p.id == 'accenture_magenta');
      default:
        return presets[1]; // Default to Accenture Signature Violet
    }
  }
}
