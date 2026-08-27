import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../services/bookmark_service.dart';
import '../../utils/chord_helper.dart';
import '../../services/chords_settings_service.dart';

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
                          min: 10.0,
                          max: 24.0,
                          divisions: 14,
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

  /// Build perfectly aligned monospace text spans (matching DB Browser font alignment)
  Widget _buildAlignedChordsView(BuildContext context, String rawText) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    // Fixed-width monospace style matching DB Browser for SQLite with dynamic _fontSize
    final monoBaseStyle = TextStyle(
      fontFamily: 'Courier',
      fontFamilyFallback: const ['Consolas', 'Courier New', 'monospace'],
      fontSize: _fontSize,
      letterSpacing: 0.0,
      wordSpacing: 0.0,
      height: 1.5,
    );

    // If chords are toggled off, render standard soft-wrapping lyrics text that flows down vertically
    if (!_showChords) {
      final baseStyle = TextStyle(fontSize: _fontSize, height: 1.6, color: textColor);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SelectableText.rich(TextSpan(children: spans)),
          ),
        );
      },
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
        children.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }
      children.add(TextSpan(
        text: match.group(0),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      children.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSong = song;
    final displayContent = _showChords && currentSong.hasChords && ChordsSettingsService.instance.value
        ? currentSong.chords
        : currentSong.content;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentSong.title.isNotEmpty ? currentSong.title : 'Song Details',
        ),
        elevation: 0,
        actions: [
          // Font Size Slider Button
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'Adjust Font Size',
            onPressed: () => _showFontSizeSlider(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentSong.title.isNotEmpty
                  ? currentSong.title
                  : 'Untitled Song',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 14),

            // Category & Chords Badges Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentSong.category.isNotEmpty)
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
                      currentSong.category,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (currentSong.hasChords)
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          color: theme.colorScheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _instrument,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Controls Toolbar: Transpose (-/+) & Instrument Choice (Guitar / Ukulele)
            if (currentSong.hasChords && _showChords && ChordsSettingsService.instance.value)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Transpose Control
                    Text(
                      'Key: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 20,
                      ),
                      tooltip: 'Transpose Down',
                      onPressed: () {
                        setState(() {
                          _transposeOffset--;
                        });
                      },
                    ),
                    Text(
                      _transposeOffset >= 0
                          ? '+$_transposeOffset'
                          : '$_transposeOffset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      tooltip: 'Transpose Up',
                      onPressed: () {
                        setState(() {
                          _transposeOffset++;
                        });
                      },
                    ),
                    if (_transposeOffset != 0)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _transposeOffset = 0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),

                    // Instrument Selector Dropdown
                    DropdownButton<String>(
                      value: _instrument,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Guitar',
                          child: Text('Guitar'),
                        ),
                        DropdownMenuItem(
                          value: 'Ukulele',
                          child: Text('Ukulele'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _instrument = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

            // Main Content / Chords Reader
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showChords && currentSong.hasChords && ChordsSettingsService.instance.value
                            ? 'Chords & Lyrics'
                            : 'Lyrics & Content',
                        style: theme.textTheme.titleMedium,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: ChordsSettingsService.instance,
                        builder: (context, showChordsAndShapes, child) {
                          if (currentSong.hasChords && showChordsAndShapes) {
                            return IconButton(
                              icon: Icon(
                                _showChords
                                    ? Icons.music_note_rounded
                                    : Icons.music_note_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: 'Toggle Chords',
                              onPressed: () {
                                setState(() {
                                  _showChords = !_showChords;
                                });
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  Divider(color: theme.dividerColor, height: 24),

                  // DB Browser Monospace Aligned Text View
                  displayContent.isNotEmpty
                      ? _buildAlignedChordsView(context, displayContent)
                      : Text(
                          'No lyrics or content available for this song.',
                          style: theme.textTheme.bodyMedium,
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleBookmark,
        tooltip: _isBookmarked ? 'Remove Bookmark' : 'Bookmark Song',
        child: Icon(
          _isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
        ),
      ),
    );
  }
}
