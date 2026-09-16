import 'package:flutter/material.dart';
import '../services/database_helper.dart';

const Set<String> newTestamentBookIds = {
  'MT', 'MK', 'LK', 'JN', 'AC', 'RM', 'C1', 'C2', 'GL', 'EP', 'PP', 'CL',
  'H1', 'H2', 'T1', 'T2', 'TT', 'PM', 'HB', 'JM', 'P1', 'P2', 'J1', 'J2', 'J3', 'JD', 'RV'
};

class BibleSelectorSheet extends StatefulWidget {
  final List<Map<String, String>> books;
  final Map<String, String>? initialBook;
  final int initialChapter;
  final int? initialVerse;
  final int initialTabIndex; // 0 for Book, 1 for Chapter, 2 for Verse
  final void Function(Map<String, String> book, int chapter, int? verse) onSelectionComplete;

  const BibleSelectorSheet({
    super.key,
    required this.books,
    this.initialBook,
    this.initialChapter = 1,
    this.initialVerse,
    this.initialTabIndex = 0,
    required this.onSelectionComplete,
  });

  static void show(
    BuildContext context, {
    required List<Map<String, String>> books,
    Map<String, String>? initialBook,
    int initialChapter = 1,
    int? initialVerse,
    int initialTabIndex = 0,
    required void Function(Map<String, String> book, int chapter, int? verse) onSelectionComplete,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BibleSelectorSheet(
          books: books,
          initialBook: initialBook,
          initialChapter: initialChapter,
          initialVerse: initialVerse,
          initialTabIndex: initialTabIndex,
          onSelectionComplete: onSelectionComplete,
        );
      },
    );
  }

  @override
  State<BibleSelectorSheet> createState() => _BibleSelectorSheetState();
}

class _BibleSelectorSheetState extends State<BibleSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String>? _selectedBook;
  int _selectedChapter = 1;
  int? _selectedVerse;

  int _chaptersCount = 0;
  bool _isLoadingChapters = false;

  int _versesCount = 0;
  bool _isLoadingVerses = false;

  String _bookSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _selectedBook = widget.initialBook ?? (widget.books.isNotEmpty ? widget.books.first : null);
    _selectedChapter = widget.initialChapter;
    _selectedVerse = widget.initialVerse;

    if (_selectedBook != null) {
      _loadChaptersCount(_selectedBook!['book_id']!);
      _loadVersesCount(_selectedBook!['book_id']!, _selectedChapter);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChaptersCount(String bookId) async {
    setState(() => _isLoadingChapters = true);
    try {
      final count = await DatabaseHelper.getBibleChaptersCount(bookId);
      if (mounted) {
        setState(() {
          _chaptersCount = count;
          _isLoadingChapters = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChapters = false);
    }
  }

  Future<void> _loadVersesCount(String bookId, int chapter) async {
    setState(() => _isLoadingVerses = true);
    try {
      final count = await DatabaseHelper.getBibleVersesCount(bookId, chapter);
      if (mounted) {
        setState(() {
          _versesCount = count;
          _isLoadingVerses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVerses = false);
    }
  }

  void _onBookSelected(Map<String, String> book) async {
    setState(() {
      _selectedBook = book;
      _selectedChapter = 1;
      _selectedVerse = null;
    });
    await _loadChaptersCount(book['book_id']!);
    await _loadVersesCount(book['book_id']!, 1);
    if (mounted) {
      _tabController.animateTo(1);
    }
  }

  void _onChapterSelected(int chapter) async {
    setState(() {
      _selectedChapter = chapter;
      _selectedVerse = null;
    });
    if (_selectedBook != null) {
      await _loadVersesCount(_selectedBook!['book_id']!, chapter);
    }
    if (mounted) {
      _tabController.animateTo(2);
    }
  }

  void _onVerseSelected(int? verse) {
    if (_selectedBook == null) return;
    Navigator.of(context).pop();
    widget.onSelectionComplete(_selectedBook!, _selectedChapter, verse);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredBooks = widget.books.where((b) {
      if (_bookSearchQuery.isEmpty) return true;
      final name = (b['book_name'] ?? '').toLowerCase();
      final id = (b['book_id'] ?? '').toLowerCase();
      final q = _bookSearchQuery.toLowerCase().trim();
      return name.contains(q) || id.contains(q);
    }).toList();

    final oldTestamentBooks = filteredBooks
        .where((b) => !newTestamentBookIds.contains(b['book_id']))
        .toList();
    final newTestamentBooks = filteredBooks
        .where((b) => newTestamentBookIds.contains(b['book_id']))
        .toList();

    final String currentBookName = _selectedBook?['book_name'] ?? 'Book';

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

          // Header summary breadcrumb
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fast Lookup',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedVerse != null
                        ? '$currentBookName $_selectedChapter:$_selectedVerse'
                        : '$currentBookName $_selectedChapter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3-step TabBar (Book > Chapter > Verse)
          TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('1. Book'),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.dividerColor,
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('2. Chapter'),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.dividerColor,
                    ),
                  ],
                ),
              ),
              const Tab(text: '3. Verse'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: BOOKS
                _buildBooksTab(
                  theme,
                  isDark,
                  oldTestamentBooks,
                  newTestamentBooks,
                ),

                // TAB 2: CHAPTERS
                _buildChaptersTab(theme, isDark, currentBookName),

                // TAB 3: VERSES
                _buildVersesTab(theme, isDark, currentBookName),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBooksTab(
    ThemeData theme,
    bool isDark,
    List<Map<String, String>> otBooks,
    List<Map<String, String>> ntBooks,
  ) {
    return Column(
      children: [
        // Quick filter input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _bookSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Filter books (e.g. Genesis, Mateo)...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2B2E) : const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (otBooks.isNotEmpty) ...[
                _buildSectionHeader('DAAN A TULAG (OLD TESTAMENT)', otBooks.length, theme),
                const SizedBox(height: 8),
                _buildBooksList(otBooks, theme, isDark),
                const SizedBox(height: 20),
              ],
              if (ntBooks.isNotEmpty) ...[
                _buildSectionHeader('BARO A TULAG (NEW TESTAMENT)', ntBooks.length, theme),
                const SizedBox(height: 8),
                _buildBooksList(ntBooks, theme, isDark),
              ],
              if (otBooks.isEmpty && ntBooks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No books matching "$_bookSearchQuery"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, ThemeData theme) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: theme.colorScheme.primary,
          ),
        ),
        const Spacer(),
        Text(
          '$count Books',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBooksList(
    List<Map<String, String>> books,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final book = books[index];
        final bookId = book['book_id'] ?? '';
        final bookName = book['book_name'] ?? '';
        final isSelected = bookId == _selectedBook?['book_id'];

        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.10)
                : (isDark ? const Color(0xFF22232A) : const Color(0xFFF7F8FA)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF33343E) : const Color(0xFFE5E7EB)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _onBookSelected(book),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Book abbreviation badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? const Color(0xFF2E303B) : const Color(0xFFEAECEF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          bookId,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFD0D2DE) : const Color(0xFF4B5563)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Book name
                    Expanded(
                      child: Text(
                        bookName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14)),
                        ),
                      ),
                    ),

                    // Trailing chevron or checkmark
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChaptersTab(ThemeData theme, bool isDark, String currentBookName) {
    if (_isLoadingChapters) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chaptersCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Please select a book first.'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Go to Books'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _chaptersCount,
      itemBuilder: (context, index) {
        final chapterNum = index + 1;
        final isSelected = chapterNum == _selectedChapter;

        return ElevatedButton(
          onPressed: () => _onChapterSelected(chapterNum),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF2A2B2E) : const Color(0xFFF0F2F5)),
            foregroundColor: isSelected
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF0E0E14)),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '$chapterNum',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersesTab(ThemeData theme, bool isDark, String currentBookName) {
    if (_isLoadingVerses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_versesCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_list_numbered_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No verses found for this chapter.'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Back to Chapters'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _versesCount,
      itemBuilder: (context, index) {
        final verseNum = index + 1;
        final isSelected = verseNum == _selectedVerse;

        return ElevatedButton(
          onPressed: () => _onVerseSelected(verseNum),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF2A2B2E) : const Color(0xFFF0F2F5)),
            foregroundColor: isSelected
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF0E0E14)),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '$verseNum',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
