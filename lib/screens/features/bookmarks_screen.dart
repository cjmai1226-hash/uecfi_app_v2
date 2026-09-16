import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../services/bookmark_service.dart';
import '../../services/database_helper.dart';
import '../details/song_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<SongModel> _bookmarkedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookmarkedTitles = await BookmarkService.getBookmarkedSongTitles();
      final allSongs = await DatabaseHelper.getAllSongs();

      final filtered = allSongs.where((song) => bookmarkedTitles.contains(song.title)).toList();

      setState(() {
        _bookmarkedSongs = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Songs'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 56,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Bookmarks Yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the bookmark icon on any song to save it here.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarkedSongs.length,
                  itemBuilder: (context, index) {
                    final song = _bookmarkedSongs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SongDetailScreen(
                                songs: _bookmarkedSongs,
                                initialIndex: index,
                              ),
                            ),
                          );
                          _loadBookmarks();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Chords Badge
                                    if (song.hasChords) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondary
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: theme.colorScheme.secondary
                                                .withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .music_note_rounded,
                                              size: 12,
                                              color: theme
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              'Chords',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: theme
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],

                                    // Song Title
                                    Text(
                                      song.title.isNotEmpty
                                          ? song.title
                                          : 'Untitled Song',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (song.content.isNotEmpty) ...[
                                      const SizedBox(height: 4),

                                      // Lyrics Content Snippet (1 Maxline)
                                      Text(
                                        song.content
                                            .replaceAll(
                                                RegExp(r'\s+'), ' ')
                                            .trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 13,
                                          color: theme.textTheme
                                              .bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Trailing Chevron Icon
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.hintColor,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
