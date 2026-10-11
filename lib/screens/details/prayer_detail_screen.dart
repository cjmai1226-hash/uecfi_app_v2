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
  bool _showCollapsedTitle = false;

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
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                final isCollapsed = notification.metrics.pixels > 40;
                if (isCollapsed != _showCollapsedTitle) {
                  setState(() {
                    _showCollapsedTitle = isCollapsed;
                  });
                }
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  title: AnimatedOpacity(
                    opacity: _showCollapsedTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.format_size_rounded),
                      tooltip: 'Adjust Font Size (${_fontSize.toInt()} px)',
                      onPressed: () => _showFontSizeSlider(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                        if (currentPrayer.category.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              currentPrayer.category,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: SelectableText(
                        content.isNotEmpty
                            ? content
                            : 'No prayer content available.',
                        textAlign: TextAlign.justify,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: _fontSize,
                          height: 1.8,
                          color: context.contentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
