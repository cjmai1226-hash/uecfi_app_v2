import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
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

      final filtered = allSongs
          .where((song) => bookmarkedTitles.contains(song.title))
          .toList();

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
      appBar: AppBar(title: const Text('Bookmarked Songs'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    icon: HugeIcons.strokeRoundedBookmark02,
                    size: 52,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Song Title & Note Icon (if hasChords)
                          Text.rich(
                            TextSpan(
                              style:
                                  theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '| ',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: song.title.isNotEmpty
                                      ? song.title
                                      : 'Untitled Song',
                                ),
                                if (song.hasChords)
                                  WidgetSpan(
                                    alignment:
                                        PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 6),
                                      child: AppIcon(
                                        icon: HugeIcons
                                            .strokeRoundedMusicNote01,
                                        size: 15,
                                        color:
                                            theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (song.content.isNotEmpty) ...[
                            const SizedBox(height: 4),

                            // Lyrics Content Snippet (2 Maxlines)
                            Text(
                              song.content
                                  .replaceAll(RegExp(r'\s+'), ' ')
                                  .trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
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
