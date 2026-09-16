import 'package:flutter/material.dart';
import '../../models/prayer_model.dart';
import '../../services/prayer_language_service.dart';
import '../../utils/theme.dart';

class PrayerDetailScreen extends StatefulWidget {
  final PrayerModel? prayer;
  final List<PrayerModel>? prayers;
  final int initialIndex;

  const PrayerDetailScreen({
    super.key,
    this.prayer,
    this.prayers,
    this.initialIndex = 0,
  });

  PrayerModel get resolvedPrayer {
    if (prayer != null) return prayer!;
    if (prayers != null && initialIndex >= 0 && initialIndex < prayers!.length) {
      return prayers![initialIndex];
    }
    return const PrayerModel(
      title: '',
      title1: '',
      content: '',
      content1: '',
      category: '',
    );
  }

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  double _fontSize = 19.0;

  /// Open Font Size Slider Bottom Sheet
  void _showFontSizeSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Font Size',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_fontSize.toInt()} px',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 12.0,
                            max: 28.0,
                            divisions: 16,
                            label: '${_fontSize.toInt()} px',
                            onChanged: (val) {
                              setModalState(() {});
                              setState(() {
                                _fontSize = val;
                              });
                            },
                          ),
                        ),
                        const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Helper to convert title to title case
  String _capitalizeTitle(String text) {
    if (text.trim().isEmpty) return 'Untitled Prayer';
    final words = text.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPrayer = widget.resolvedPrayer;

    return ValueListenableBuilder<String>(
      valueListenable: PrayerLanguageService.instance,
      builder: (context, langCode, child) {
        final title = currentPrayer.getDisplayTitle(langCode);
        final content = currentPrayer.getDisplayContent(langCode);
        final displayTitle = _capitalizeTitle(title);

        return Scaffold(
          appBar: AppBar(
            title: Image.asset(
              'assets/images/brand_mark.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.format_size_rounded),
                tooltip: 'Adjust Font Size',
                onPressed: () => _showFontSizeSlider(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Category Badge
                if (currentPrayer.category.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF3A3B3C)
                          : const Color(0xFFE4E6EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentPrayer.category,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 8),

                // Main Content Reader
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: SelectableText(
                    content.isNotEmpty
                        ? content
                        : 'No prayer content available.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: context.contentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
