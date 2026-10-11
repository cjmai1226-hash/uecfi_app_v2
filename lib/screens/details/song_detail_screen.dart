import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../models/song_model.dart';
import '../../services/bookmark_service.dart';
import '../../utils/chord_helper.dart';
import '../../services/chords_settings_service.dart';
import '../../utils/theme.dart';

class SongDetailScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int initialIndex;

  const SongDetailScreen({
    super.key,
    required this.songs,
    required this.initialIndex,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late int _currentIndex;
  bool _showChords = false;
  int _transposeOffset = 0;
  String _instrument = 'Guitar'; // 'Guitar' or 'Ukulele'
  double _fontSize = 19.0; // Reader font size
  bool _isBookmarked = false;
  bool _showCollapsedTitle = false;

  SongModel get song => widget.songs[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final bookmarked = await BookmarkService.isBookmarked(song.title);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final newStatus = await BookmarkService.toggleBookmark(song.title);
    if (mounted) {
      setState(() {
        _isBookmarked = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Added "${song.title}" to Bookmarks'
                : 'Removed "${song.title}" from Bookmarks',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  /// Open Chords & Playing Tools Bottom Sheet
  void _showChordsToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final canShowChords =
                song.hasChords && ChordsSettingsService.instance.value;
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (canShowChords) ...[
                      // 1. Show Chords Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Show Chords',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: DropdownButton<bool>(
                                value: _showChords,
                                isDense: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(
                                    value: true,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Show'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: false,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_off_outlined,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Hide'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    setModalState(() {});
                                    setState(() {
                                      _showChords = newVal;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_showChords) ...[
                        Divider(
                          height: 28,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        // 2. Key Transpose Controls (-5 to +5 stepper, no reset)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Key Transpose',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton.filledTonal(
                                  icon: const Icon(
                                    Icons.remove_rounded,
                                    size: 18,
                                  ),
                                  tooltip: 'Transpose Down',
                                  onPressed: _transposeOffset > -5
                                      ? () {
                                          setModalState(() {});
                                          setState(() {
                                            _transposeOffset--;
                                          });
                                        }
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    _transposeOffset > 0
                                        ? '+$_transposeOffset'
                                        : '$_transposeOffset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  tooltip: 'Transpose Up',
                                  onPressed: _transposeOffset < 5
                                      ? () {
                                          setModalState(() {});
                                          setState(() {
                                            _transposeOffset++;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(
                          height: 28,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        // 3. Instrument Choice (Guitar / Ukulele)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instrument Diagrams',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Fingerings for chord popups',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  value: _instrument,
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down_rounded,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Guitar',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.music_note_rounded,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Guitar'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Ukulele',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.queue_music_rounded,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Ukulele'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (newVal) {
                                    if (newVal != null) {
                                      setModalState(() {});
                                      setState(() {
                                        _instrument = newVal;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      Divider(
                        height: 28,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                    ],

                    // 4. Font Size Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Font Size',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: DropdownButton<double>(
                              value: [
                                14.0,
                                16.0,
                                18.0,
                                19.0,
                                21.0,
                                24.0,
                              ].contains(_fontSize)
                                  ? _fontSize
                                  : 19.0,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(
                                  value: 14.0,
                                  child: Text('14 px (Small)'),
                                ),
                                DropdownMenuItem(
                                  value: 16.0,
                                  child: Text('16 px (Normal)'),
                                ),
                                DropdownMenuItem(
                                  value: 18.0,
                                  child: Text('18 px (Medium)'),
                                ),
                                DropdownMenuItem(
                                  value: 19.0,
                                  child: Text('19 px (Default)'),
                                ),
                                DropdownMenuItem(
                                  value: 21.0,
                                  child: Text('21 px (Large)'),
                                ),
                                DropdownMenuItem(
                                  value: 24.0,
                                  child: Text('24 px (Extra Large)'),
                                ),
                              ],
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setModalState(() {});
                                  setState(() {
                                    _fontSize = newVal;
                                  });
                                }
                              },
                            ),
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

  /// Build perfectly aligned monospace text spans (matching DB Browser font alignment)
  Widget _buildAlignedChordsView(BuildContext context, String rawText) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = context.contentColor;

    // Fixed-width monospace style matching DB Browser for SQLite with dynamic _fontSize
    final monoBaseStyle = TextStyle(
      fontFamily: 'Courier',
      fontFamilyFallback: const ['Consolas', 'Courier New', 'monospace'],
      fontSize: _fontSize,
      letterSpacing: 0.0,
      wordSpacing: 0.0,
      height: 1.5,
      color: textColor,
    );

    // If chords are toggled off, render standard soft-wrapping lyrics text that flows down vertically
    if (!_showChords) {
      final baseStyle = TextStyle(
        fontSize: _fontSize,
        height: 1.6,
        color: textColor,
      );
      return SelectableText.rich(
        _parseLyricsWithBoldKeywords(rawText, baseStyle),
      );
    }

    // Replace tabs with 4 spaces for exact DB Browser column alignment
    final processedText = rawText.replaceAll('\t', '    ');
    final lines = processedText.split('\n');
    final chordPattern = RegExp(r'(\S+)');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('>')) {
        final gtIndex = line.indexOf('>');
        final prefixSpaces = line.substring(0, gtIndex);
        final content = line.substring(gtIndex + 1);

        // Preserve any spaces before >
        if (prefixSpaces.isNotEmpty) {
          spans.add(
            TextSpan(
              text: prefixSpaces,
              style: monoBaseStyle.copyWith(
                color: textColor.withValues(alpha: 0.4),
              ),
            ),
          );
        }

        // Process chord tokens and spaces
        content.splitMapJoin(
          chordPattern,
          onMatch: (Match m) {
            final word = m.group(0)!;
            final baseChord = ChordHelper.cleanChordName(word);
            final transposedChord = ChordHelper.transposeChord(
              baseChord,
              _transposeOffset,
            );

            spans.add(
              TextSpan(
                text: transposedChord,
                style: monoBaseStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    ChordHelper.showChordDiagram(
                      context,
                      transposedChord,
                      instrument: _instrument,
                    );
                  },
              ),
            );
            return '';
          },
          onNonMatch: (String nonMatch) {
            spans.add(
              TextSpan(
                text: nonMatch,
                style: monoBaseStyle.copyWith(color: textColor),
              ),
            );
            return '';
          },
        );
      } else {
        // Standard verse / lyrics line (rendered in identical monospace style so columns match 1:1)
        spans.add(
          TextSpan(
            text: line,
            style: monoBaseStyle.copyWith(color: textColor),
          ),
        );
      }

      // Add newline after line
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  TextSpan _parseLyricsWithBoldKeywords(String text, TextStyle baseStyle) {
    final regex = RegExp(
      r'\b(Repeat Coro|Repeat Chorus|Repeat Koro|Coro|Chorus|Koro)\b',
      caseSensitive: false,
    );

    final List<TextSpan> children = [];
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        children.add(
          TextSpan(text: text.substring(start, match.start), style: baseStyle),
        );
      }
      children.add(
        TextSpan(
          text: match.group(0),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSong = song;
    final displayContent =
        _showChords &&
            currentSong.hasChords &&
            ChordsSettingsService.instance.value
        ? currentSong.chords
        : currentSong.content;

    final displayTitle =
        currentSong.title.isNotEmpty ? currentSong.title : 'Untitled Song';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleBookmark,
        tooltip: _isBookmarked ? 'Remove Bookmark' : 'Bookmark Song',
        child: AppIcon(
          icon: _isBookmarked
              ? HugeIcons.strokeRoundedBookmark02
              : HugeIcons.strokeRoundedBookmark02,
        ),
      ),
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
                  icon: const AppIcon(
                    icon: HugeIcons.strokeRoundedMoreHorizontalCircle02,
                  ),
                  tooltip: 'Chords & Reading Tools',
                  onPressed: () => _showChordsToolsSheet(context),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expanded full title
                    Text(
                      displayTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                    if (currentSong.author.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'By ${currentSong.author}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (currentSong.category.isNotEmpty) ...[
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
                          currentSong.category,
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverToBoxAdapter(
                child: displayContent.isNotEmpty
                    ? _buildAlignedChordsView(context, displayContent)
                    : Text(
                        'No lyrics or content available for this song.',
                        style: theme.textTheme.bodyMedium,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
