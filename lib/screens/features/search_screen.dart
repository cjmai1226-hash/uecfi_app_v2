import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_helper.dart';
import '../../services/prayer_language_service.dart';
import '../../models/center_model.dart';
import '../../models/song_model.dart';
import '../../models/prayer_model.dart';
import '../../models/bylaw_model.dart';
import '../details/center_detail_screen.dart';
import '../details/song_detail_screen.dart';
import '../details/prayer_detail_screen.dart';
import '../details/bylaw_detail_screen.dart';

enum SearchCategory { all, centers, songs, prayers, bylaws }

enum SearchResultType { center, song, prayer, bylaw }

class SearchResultItem {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String? badge;
  final dynamic data;

  const SearchResultItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.data,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<CenterModel> _allCenters = [];
  List<SongModel> _allSongs = [];
  List<PrayerModel> _allPrayers = [];
  List<BylawModel> _allBylaws = [];

  List<SearchResultItem> _searchResults = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SearchCategory _selectedCategory = SearchCategory.all;

  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      });
    } catch (_) {}
  }

  Future<void> _addRecentSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    
    setState(() {
      _recentSearches.remove(cleanQuery);
      _recentSearches.insert(0, cleanQuery);
      if (_recentSearches.length > 8) {
        _recentSearches = _recentSearches.sublist(0, 8);
      }
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (_) {}
  }

  Future<void> _deleteRecentSearch(String query) async {
    setState(() {
      _recentSearches.remove(query);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (_) {}
  }

  Future<void> _clearAllRecentSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final centers = await DatabaseHelper.getAllCenters();
      final songs = await DatabaseHelper.getAllSongs();
      final prayers = await DatabaseHelper.getAllPrayers();
      final bylaws = await DatabaseHelper.getAllBylaws();

      if (mounted) {
        setState(() {
          _allCenters = centers;
          _allSongs = songs;
          _allPrayers = prayers;
          _allBylaws = bylaws;
          _isLoading = false;
        });
        _performSearch(_searchQuery);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _searchResults = [];
        return;
      }

      final List<SearchResultItem> results = [];
      final activeLang = PrayerLanguageService.instance.value;

      // 1. Search Centers
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.centers) {
        for (var center in _allCenters) {
          if (center.name.toLowerCase().contains(_searchQuery) ||
              center.address.toLowerCase().contains(_searchQuery) ||
              center.district.toLowerCase().contains(_searchQuery) ||
              center.location.toLowerCase().contains(_searchQuery) ||
              center.area.toLowerCase().contains(_searchQuery)) {
            results.add(
              SearchResultItem(
                type: SearchResultType.center,
                title: center.name,
                subtitle: center.address.isNotEmpty ? center.address : 'District: ${center.district}',
                badge: center.district.isNotEmpty ? center.district : null,
                data: center,
              ),
            );
          }
        }
      }

      // 2. Search Songs
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.songs) {
        for (var song in _allSongs) {
          if (song.title.toLowerCase().contains(_searchQuery) ||
              song.author.toLowerCase().contains(_searchQuery) ||
              song.category.toLowerCase().contains(_searchQuery) ||
              song.content.toLowerCase().contains(_searchQuery) ||
              song.chords.toLowerCase().contains(_searchQuery)) {
            results.add(
              SearchResultItem(
                type: SearchResultType.song,
                title: song.title,
                subtitle: song.author.isNotEmpty ? 'By ${song.author}' : _previewText(song.content),
                badge: song.category.isNotEmpty ? song.category : (song.hasChords ? 'Chords' : null),
                data: song,
              ),
            );
          }
        }
      }

      // 3. Search Prayers
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.prayers) {
        for (var prayer in _allPrayers) {
          final displayTitle = prayer.getDisplayTitle(activeLang);
          final displayContent = prayer.getDisplayContent(activeLang);

          if (prayer.title.toLowerCase().contains(_searchQuery) ||
              prayer.title1.toLowerCase().contains(_searchQuery) ||
              prayer.content.toLowerCase().contains(_searchQuery) ||
              prayer.content1.toLowerCase().contains(_searchQuery) ||
              prayer.category.toLowerCase().contains(_searchQuery)) {
            results.add(
              SearchResultItem(
                type: SearchResultType.prayer,
                title: displayTitle.isNotEmpty ? displayTitle : 'Untitled Prayer',
                subtitle: _previewText(displayContent),
                badge: prayer.page != null ? 'Page ${prayer.page}' : null,
                data: prayer,
              ),
            );
          }
        }
      }

      // 4. Search Bylaws
      if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.bylaws) {
        for (var bylaw in _allBylaws) {
          if (bylaw.title.toLowerCase().contains(_searchQuery) ||
              bylaw.content.toLowerCase().contains(_searchQuery) ||
              (bylaw.chapters != null && bylaw.chapterTag.toLowerCase().contains(_searchQuery))) {
            results.add(
              SearchResultItem(
                type: SearchResultType.bylaw,
                title: bylaw.title,
                subtitle: _previewText(bylaw.content),
                badge: bylaw.chapters != null ? bylaw.chapterTag : null,
                data: bylaw,
              ),
            );
          }
        }
      }

      _searchResults = results;
    });
  }

  String _previewText(String text) {
    if (text.trim().isEmpty) return '';
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 80 ? clean : '${clean.substring(0, 80)}...';
  }

  void _onCategorySelected(SearchCategory cat) {
    setState(() {
      _selectedCategory = cat;
    });
    _performSearch(_searchQuery);
  }

  void _navigateToDetail(SearchResultItem item) {
    if (_searchController.text.trim().isNotEmpty) {
      _addRecentSearch(_searchController.text);
    }
    if (item.type == SearchResultType.center) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CenterDetailScreen(center: item.data as CenterModel),
        ),
      );
    } else if (item.type == SearchResultType.song) {
      final targetSong = item.data as SongModel;
      final matchedSongs = _searchResults.where((r) => r.type == SearchResultType.song).map((r) => r.data as SongModel).toList();
      final idx = matchedSongs.indexOf(targetSong);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SongDetailScreen(
            songs: matchedSongs.isNotEmpty ? matchedSongs : _allSongs,
            initialIndex: idx >= 0 ? idx : 0,
          ),
        ),
      );
    } else if (item.type == SearchResultType.prayer) {
      final targetPrayer = item.data as PrayerModel;
      final matchedPrayers = _searchResults.where((r) => r.type == SearchResultType.prayer).map((r) => r.data as PrayerModel).toList();
      final idx = matchedPrayers.indexOf(targetPrayer);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PrayerDetailScreen(
            prayers: matchedPrayers.isNotEmpty ? matchedPrayers : _allPrayers,
            initialIndex: idx >= 0 ? idx : 0,
          ),
        ),
      );
    } else if (item.type == SearchResultType.bylaw) {
      final targetBylaw = item.data as BylawModel;
      final matchedBylaws = _searchResults.where((r) => r.type == SearchResultType.bylaw).map((r) => r.data as BylawModel).toList();
      final idx = matchedBylaws.indexOf(targetBylaw);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BylawDetailScreen(
            bylaws: matchedBylaws.isNotEmpty ? matchedBylaws : _allBylaws,
            initialIndex: idx >= 0 ? idx : 0,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF3A3B3C)
                : const Color(0xFFE4E6EB),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _performSearch,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _addRecentSearch(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search songs, prayers, bylaws, centers...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', SearchCategory.all, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Songs', SearchCategory.songs, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Prayers', SearchCategory.prayers, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Bylaws', SearchCategory.bylaws, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Centers', SearchCategory.centers, theme),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.isEmpty
                    ? _recentSearches.isNotEmpty
                        ? _buildRecentSearchesView(theme)
                        : _buildEmptyPlaceholder(theme)
                    : _searchResults.isEmpty
                        ? _buildNoResultsPlaceholder(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return _buildResultCard(context, item);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchCategory cat, ThemeData theme) {
    final isSelected = _selectedCategory == cat;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF3A3B3C)
          : const Color(0xFFE4E6EB),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (_) => _onCategorySelected(cat),
    );
  }

  Widget _buildRecentSearchesView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: _clearAllRecentSearches,
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Divider(color: theme.dividerColor, height: 1),
        ..._recentSearches.map((query) {
          return ListTile(
            leading: Icon(
              Icons.history_rounded,
              color: theme.disabledColor,
            ),
            title: Text(query),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => _deleteRecentSearch(query),
              splashRadius: 20,
            ),
            onTap: () {
              _searchController.text = query;
              _performSearch(query);
            },
          );
        }),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Unified Search',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type to search across Worship Songs, Prayers, Church Bylaws, and Worship Centers',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 48,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching results found',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching with a different term or category',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResultItem item) {
    final theme = Theme.of(context);

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (item.type) {
      case SearchResultType.song:
        typeColor = const Color(0xFF0084FF); // Messenger Blue-Cyan
        typeIcon = Icons.music_note_rounded;
        typeLabel = 'SONG';
        break;
      case SearchResultType.prayer:
        typeColor = const Color(0xFF8A3AB9); // Messenger Purple
        typeIcon = Icons.import_contacts_rounded;
        typeLabel = 'PRAYER';
        break;
      case SearchResultType.bylaw:
        typeColor = const Color(0xFF00A400); // Meta Green
        typeIcon = Icons.description_rounded;
        typeLabel = 'BYLAW';
        break;
      case SearchResultType.center:
        typeColor = theme.colorScheme.primary; // Facebook Blue
        typeIcon = Icons.church_rounded;
        typeLabel = 'CENTER';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Icon & Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 13, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2) ?? Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),

                // Subtitle / Preview Text
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
