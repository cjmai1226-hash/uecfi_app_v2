import 'package:flutter/material.dart';
import '../../models/bible_verse_model.dart';
import '../../services/database_helper.dart';
import '../../widgets/bible_selector_sheet.dart';

class BibleScreen extends StatefulWidget {
  final Map<String, String>? initialBook;
  final int initialChapter;
  final int? initialVerse;

  const BibleScreen({
    super.key,
    this.initialBook,
    this.initialChapter = 1,
    this.initialVerse,
  });

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  bool _isLoading = true;
  List<Map<String, String>> _allBooks = [];
  Map<String, String>? _selectedBook;
  int _selectedChapter = 1;
  int? _highlightedVerse;

  int _chaptersCount = 0;
  List<BibleVerseModel> _verses = [];
  double _fontSize = 18.0;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<BibleVerseModel> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedChapter = widget.initialChapter;
    _highlightedVerse = widget.initialVerse;
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final books = await DatabaseHelper.getBibleBooks();
      if (books.isNotEmpty) {
        _allBooks = books;
        _selectedBook = widget.initialBook ?? books.first;
        await _loadChapterContent(targetVerse: _highlightedVerse);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading Bible initial data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChapterContent({int? targetVerse}) async {
    if (_selectedBook == null) return;

    setState(() => _isLoading = true);

    try {
      final bookId = _selectedBook!['book_id']!;
      final count = await DatabaseHelper.getBibleChaptersCount(bookId);
      final verses = await DatabaseHelper.getBibleVerses(bookId, _selectedChapter);

      _verseKeys.clear();
      for (final v in verses) {
        _verseKeys[v.verse] = GlobalKey();
      }

      if (mounted) {
        setState(() {
          _chaptersCount = count;
          _verses = verses;
          _isLoading = false;
          _highlightedVerse = targetVerse;
        });

        // If target verse is specified, smoothly scroll to it
        if (_highlightedVerse != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToVerse(_highlightedVerse!);
          });
        } else {
          // Scroll to top when changing chapters
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading Bible chapter: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToVerse(int verseNum) {
    final key = _verseKeys[verseNum];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.25,
      );
    }
  }

  Future<void> _navigateChapter(int delta) async {
    if (_selectedBook == null) return;
    int nextChapter = _selectedChapter + delta;

    if (nextChapter >= 1 && nextChapter <= _chaptersCount) {
      setState(() {
        _selectedChapter = nextChapter;
        _highlightedVerse = null;
      });
      await _loadChapterContent();
    } else if (delta < 0) {
      // Go to previous book, last chapter
      final currentBookIndex = _allBooks.indexWhere(
        (b) => b['book_id'] == _selectedBook!['book_id'],
      );
      if (currentBookIndex > 0) {
        final prevBook = _allBooks[currentBookIndex - 1];
        final prevChaptersCount =
            await DatabaseHelper.getBibleChaptersCount(prevBook['book_id']!);
        setState(() {
          _selectedBook = prevBook;
          _selectedChapter = prevChaptersCount;
          _highlightedVerse = null;
        });
        await _loadChapterContent();
      }
    } else if (delta > 0) {
      // Go to next book, chapter 1
      final currentBookIndex = _allBooks.indexWhere(
        (b) => b['book_id'] == _selectedBook!['book_id'],
      );
      if (currentBookIndex >= 0 && currentBookIndex < _allBooks.length - 1) {
        final nextBook = _allBooks[currentBookIndex + 1];
        setState(() {
          _selectedBook = nextBook;
          _selectedChapter = 1;
          _highlightedVerse = null;
        });
        await _loadChapterContent();
      }
    }
  }

  void _openFastLookupSheet({int initialTab = 0}) {
    if (_allBooks.isEmpty) return;

    BibleSelectorSheet.show(
      context,
      books: _allBooks,
      initialBook: _selectedBook,
      initialChapter: _selectedChapter,
      initialVerse: _highlightedVerse,
      initialTabIndex: initialTab,
      onSelectionComplete: (book, chapter, verse) {
        setState(() {
          _selectedBook = book;
          _selectedChapter = chapter;
          _highlightedVerse = verse;
        });
        _loadChapterContent(targetVerse: verse);
      },
    );
  }

  void _showFontSizeSlider() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                        const Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 12.0,
                            max: 30.0,
                            divisions: 18,
                            label: '${_fontSize.toInt()} px',
                            onChanged: (val) {
                              setModalState(() {});
                              setState(() => _fontSize = val);
                            },
                          ),
                        ),
                        const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearchLoading = true);

    try {
      final results = await DatabaseHelper.searchBible(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final footnoteVerses = _verses
        .where((v) => v.footnotes != null && v.footnotes!.trim().isNotEmpty)
        .toList();

    final bookName = _selectedBook?['book_name'] ?? 'Bible';

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
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: 'Search Scriptures',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults = [];
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'Font Size',
            onPressed: _showFontSizeSlider,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search Ilocano Bible (e.g. ayat, namnama)...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2B2E) : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          Expanded(
            child: _isSearching && _searchController.text.trim().isNotEmpty
                ? _buildSearchResults(theme)
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! > 150) {
                              _navigateChapter(-1);
                            } else if (details.primaryVelocity! < -150) {
                              _navigateChapter(1);
                            }
                          }
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chapter Title
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$bookName $_selectedChapter',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ti Biblia (Ilocano)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: theme.dividerColor, height: 20),

                              // Scripture Verses
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _verses.length,
                                itemBuilder: (context, index) {
                                  final verse = _verses[index];
                                  final isTarget = _highlightedVerse == verse.verse;
                                  final hasFootnote = verse.footnotes != null &&
                                      verse.footnotes!.trim().isNotEmpty;

                                  return Container(
                                    key: _verseKeys[verse.verse],
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: isTarget
                                        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                                        : EdgeInsets.zero,
                                    decoration: isTarget
                                        ? BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: isDark ? 0.18 : 0.10),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.4),
                                            ),
                                          )
                                        : null,
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${verse.verse} ',
                                            style: TextStyle(
                                              fontSize: _fontSize * 0.85,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: verse.text,
                                            style: TextStyle(
                                              fontSize: _fontSize,
                                              height: 1.6,
                                              color: isDark
                                                  ? const Color(0xFFF5F5FA)
                                                  : const Color(0xFF0E0E14),
                                            ),
                                          ),
                                          if (hasFootnote) ...[
                                            WidgetSpan(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 2),
                                                child: Text(
                                                  '*',
                                                  style: TextStyle(
                                                    color: theme.colorScheme.primary,
                                                    fontSize: _fontSize * 0.85,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Footnotes Section
                              if (footnoteVerses.isNotEmpty) ...[
                                const SizedBox(height: 28),
                                Divider(color: theme.dividerColor, height: 28),
                                Text(
                                  'Footnotes',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...footnoteVerses.map((fv) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'v. ${fv.verse}: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            fv.footnotes ?? '',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _isSearching
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Previous Chapter',
                      onPressed: () => _navigateChapter(-1),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openFastLookupSheet(initialTab: 1),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '$bookName $_selectedChapter',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.unfold_more_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      tooltip: 'Next Chapter',
                      onPressed: () => _navigateChapter(1),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('No scriptures match your search.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              '${result.bookName} ${result.chapter}:${result.verse}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                result.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              final matchedBook = _allBooks.firstWhere(
                (b) => b['book_id'] == result.bookId,
                orElse: () => {'book_id': result.bookId, 'book_name': result.bookName},
              );
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchResults = [];
                _selectedBook = matchedBook;
                _selectedChapter = result.chapter;
                _highlightedVerse = result.verse;
              });
              _loadChapterContent(targetVerse: result.verse);
            },
          ),
        );
      },
    );
  }
}
