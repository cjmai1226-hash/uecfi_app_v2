import 'package:flutter/material.dart';
import '../../models/prayer_model.dart';
import '../../services/prayer_language_service.dart';

class PrayerDetailScreen extends StatefulWidget {
  final List<PrayerModel> prayers;
  final int initialIndex;

  const PrayerDetailScreen({
    super.key,
    required this.prayers,
    required this.initialIndex,
  });

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  late int _currentIndex;
  double _fontSize = 19.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Open Font Size Slider Bottom Sheet
  void _showFontSizeSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPrayer = widget.prayers[_currentIndex];

    return ValueListenableBuilder<String>(
      valueListenable: PrayerLanguageService.instance,
      builder: (context, langCode, child) {
        final title = currentPrayer.getDisplayTitle(langCode);
        final content = currentPrayer.getDisplayContent(langCode);

        return Scaffold(
          appBar: AppBar(
            title: Text(title.isNotEmpty ? title : 'Prayer Details'),
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
                  title.isNotEmpty ? title : 'Untitled Prayer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Category & Page Badges Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (currentPrayer.category.isNotEmpty)
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
                    if (currentPrayer.page != null)
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
                          'Page ${currentPrayer.page}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Content Reader
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prayer Content',
                        style: theme.textTheme.titleMedium,
                      ),
                      Divider(color: theme.dividerColor, height: 24),
                      SelectableText(
                        content.isNotEmpty
                            ? content
                            : 'No prayer content available.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: _fontSize,
                          height: 1.8,
                          color: theme.textTheme.bodyLarge?.color?.withValues(
                            alpha: 0.95,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Bottom Navigation Bar with Previous & Next Prayer Buttons
          bottomNavigationBar: widget.prayers.length > 1
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Prayer Button
                      IconButton.outlined(
                        onPressed: _currentIndex > 0
                            ? () {
                                setState(() {
                                  _currentIndex--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),

                      // Index Count Indicator
                      Text(
                        '${_currentIndex + 1} / ${widget.prayers.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),

                      // Next Prayer Button
                      IconButton.filled(
                        onPressed: _currentIndex < widget.prayers.length - 1
                            ? () {
                                setState(() {
                                  _currentIndex++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
