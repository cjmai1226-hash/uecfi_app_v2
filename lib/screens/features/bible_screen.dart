import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/bible_verse_model.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  bool _isLoading = true;
  List<Map<String, String>> _books = [];
  Map<String, String>? _selectedBook;
  int _chaptersCount = 0;
  int _selectedChapter = 1;
  List<BibleVerseModel> _verses = [];
  double _fontSize = 18.0;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<BibleVerseModel> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final books = await DatabaseHelper.getBibleBooks();
      if (books.isNotEmpty) {
        setState(() {
          _books = books;
          _selectedBook = books.first;
        });
        await _loadChaptersAndVerses(books.first, 1);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial Bible data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChaptersAndVerses(Map<String, String> book, int chapter) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookId = book['book_id']!;
      final chaptersCount = await DatabaseHelper.getBibleChaptersCount(bookId);
      final verses = await DatabaseHelper.getBibleVerses(bookId, chapter);

      setState(() {
        _selectedBook = book;
        _chaptersCount = chaptersCount;
        _selectedChapter = chapter;
        _verses = verses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chapter details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Change chapter relative to current (e.g. +1 or -1)
  Future<void> _navigateChapter(int delta) async {
    if (_selectedBook == null) return;
    int nextChapter = _selectedChapter + delta;

    if (nextChapter >= 1 && nextChapter <= _chaptersCount) {
      await _loadChaptersAndVerses(_selectedBook!, nextChapter);
    } else if (delta < 0) {
      // Go to previous book, last chapter
      final currentBookIndex = _books.indexOf(_selectedBook!);
      if (currentBookIndex > 0) {
        final prevBook = _books[currentBookIndex - 1];
        final prevChaptersCount = await DatabaseHelper.getBibleChaptersCount(prevBook['book_id']!);
        await _loadChaptersAndVerses(prevBook, prevChaptersCount);
      }
    } else if (delta > 0) {
      // Go to next book, chapter 1
      final currentBookIndex = _books.indexOf(_selectedBook!);
      if (currentBookIndex < _books.length - 1) {
        final nextBook = _books[currentBookIndex + 1];
        await _loadChaptersAndVerses(nextBook, 1);
      }
    }
  }

  /// Open combined Book & Chapter selector inside a single Bottom Sheet using TabBar
  void _showCombinedBookChapterSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return _CombinedBibleSelectorSheet(
          books: _books,
          initialBook: _selectedBook,
          initialChapter: _selectedChapter,
          onSelectionComplete: (book, chapter) {
            Navigator.pop(context);
            _loadChaptersAndVerses(book, chapter);
          },
        );
      },
    );
  }

  /// Open Font Size Slider Bottom Sheet
  void _showFontSizeSlider() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    try {
      final results = await DatabaseHelper.searchBible(query);
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    } catch (e) {
      debugPrint('Error performing Bible search: $e');
      setState(() {
        _isSearchLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build footnotes list
    final footnoteVerses = _verses.where((v) => v.footnotes != null && v.footnotes!.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilocano Bible (Ilodor)'),
        elevation: 0,
        actions: [
          // Search toggle button
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: 'Search Bible',
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
          // Font size selector button
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'Adjust Font Size',
            onPressed: _showFontSizeSlider,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Row below AppBar
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search Ilocano Bible...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                            _performSearch('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? const Color(0xFF3A3B3C)
                      : const Color(0xFFE4E6EB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          // Main body content
          Expanded(
            child: _isSearching && _searchController.text.trim().isNotEmpty
                ? _buildSearchView(theme)
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! > 100) {
                              _navigateChapter(-1);
                            } else if (details.primaryVelocity! < -100) {
                              _navigateChapter(1);
                            }
                          }
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedBook?["book_name"]} $_selectedChapter',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Divider(color: theme.dividerColor, height: 24),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _verses.length,
                                itemBuilder: (context, index) {
                                  final verse = _verses[index];
                                  final hasFootnote = verse.footnotes != null && verse.footnotes!.trim().isNotEmpty;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${verse.verse} ',
                                            style: TextStyle(
                                              fontSize: _fontSize * 0.8,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: verse.text,
                                            style: TextStyle(
                                              fontSize: _fontSize,
                                              height: 1.6,
                                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.95),
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
                                                    fontSize: _fontSize * 0.8,
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
                              if (footnoteVerses.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                Divider(color: theme.dividerColor, height: 32),
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
      bottomNavigationBar: _isSearching
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous Chapter',
                      onPressed: () => _navigateChapter(-1),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _showCombinedBookChapterSelector,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_selectedBook?["book_name"]} $_selectedChapter',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next Chapter',
                      onPressed: () => _navigateChapter(1),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchView(ThemeData theme) {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text('Type a query to search scriptures.'),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No scriptures match your search.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
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
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              // Go directly to that book, chapter, and close search
              final matchedBook = _books.firstWhere(
                (b) => b['book_id'] == result.bookId,
                orElse: () => {'book_id': result.bookId, 'book_name': result.bookName},
              );
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchResults = [];
              });
              _loadChaptersAndVerses(matchedBook, result.chapter);
            },
          ),
        );
      },
    );
  }
}

class _CombinedBibleSelectorSheet extends StatefulWidget {
  final List<Map<String, String>> books;
  final Map<String, String>? initialBook;
  final int initialChapter;
  final void Function(Map<String, String> book, int chapter) onSelectionComplete;

  const _CombinedBibleSelectorSheet({
    required this.books,
    required this.initialBook,
    required this.initialChapter,
    required this.onSelectionComplete,
  });

  @override
  State<_CombinedBibleSelectorSheet> createState() => _CombinedBibleSelectorSheetState();
}

class _CombinedBibleSelectorSheetState extends State<_CombinedBibleSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String>? _selectedBook;
  int _chaptersCount = 0;
  bool _isLoadingChapters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBook = widget.initialBook;
    if (_selectedBook != null) {
      _loadChaptersCount(_selectedBook!['book_id']!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChaptersCount(String bookId) async {
    setState(() {
      _isLoadingChapters = true;
    });
    try {
      final count = await DatabaseHelper.getBibleChaptersCount(bookId);
      setState(() {
        _chaptersCount = count;
        _isLoadingChapters = false;
      });
    } catch (e) {
      debugPrint('Error getting chapter counts in sheet: $e');
      setState(() {
        _isLoadingChapters = false;
      });
    }
  }

  void _onBookSelected(Map<String, String> book) async {
    setState(() {
      _selectedBook = book;
    });
    await _loadChaptersCount(book['book_id']!);
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oldTestamentBooks = widget.books
        .where((b) => !_newTestamentBookIds.contains(b['book_id']))
        .toList();
    final newTestamentBooks = widget.books
        .where((b) => _newTestamentBookIds.contains(b['book_id']))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Book'),
              Tab(text: 'Chapter'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (oldTestamentBooks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                        child: Text(
                          'OLD TESTAMENT',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: oldTestamentBooks.length,
                        itemBuilder: (context, index) {
                          final book = oldTestamentBooks[index];
                          final isSelected = book['book_id'] == _selectedBook?['book_id'];
                          return _buildBookItem(book, isSelected, theme);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (newTestamentBooks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                        child: Text(
                          'NEW TESTAMENT',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: newTestamentBooks.length,
                        itemBuilder: (context, index) {
                          final book = newTestamentBooks[index];
                          final isSelected = book['book_id'] == _selectedBook?['book_id'];
                          return _buildBookItem(book, isSelected, theme);
                        },
                      ),
                    ],
                  ],
                ),
                _isLoadingChapters
                    ? const Center(child: CircularProgressIndicator())
                    : _chaptersCount == 0
                        ? const Center(child: Text('Select a book first.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _chaptersCount,
                            itemBuilder: (context, index) {
                              final chapterNum = index + 1;
                              final isSelected = _selectedBook?['book_id'] == widget.initialBook?['book_id'] &&
                                  chapterNum == widget.initialChapter;
                              return ElevatedButton(
                                onPressed: () {
                                  widget.onSelectionComplete(_selectedBook!, chapterNum);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? theme.colorScheme.primary
                                      : (theme.brightness == Brightness.dark
                                          ? const Color(0xFF3A3B3C)
                                          : const Color(0xFFE4E6EB)),
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : (theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  '$chapterNum',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(Map<String, String> book, bool isSelected, ThemeData theme) {
    return ElevatedButton(
      onPressed: () => _onBookSelected(book),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : (theme.brightness == Brightness.dark
                ? const Color(0xFF3A3B3C)
                : const Color(0xFFE4E6EB)),
        foregroundColor: isSelected
            ? theme.colorScheme.primary
            : (theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : null,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        book['book_name'] ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

const Set<String> _newTestamentBookIds = {
  'MT', 'MK', 'LK', 'JN', 'AC', 'RM', 'C1', 'C2', 'GL', 'EP', 'PP', 'CL',
  'H1', 'H2', 'T1', 'T2', 'TT', 'PM', 'HB', 'JM', 'P1', 'P2', 'J1', 'J2', 'J3', 'JD', 'RV'
};
