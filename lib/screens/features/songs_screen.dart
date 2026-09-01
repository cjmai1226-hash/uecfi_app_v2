import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/song_model.dart';
import '../../widgets/feed_composer_card.dart';
import 'bookmarks_screen.dart';
import 'submit_song_screen.dart';
import '../details/song_detail_screen.dart';
import '../../services/ad_service.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongsData();
  }

  Future<void> _loadSongsData() async {
    try {
      final songs = await DatabaseHelper.getAllSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Truncate long content string for preview display
  String _getContentPreview(String content) {
    if (content.trim().isEmpty) return 'No preview available.';
    final cleanText = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanText.length <= 100) return cleanText;
    return '${cleanText.substring(0, 100)}...';
  }

  Widget _buildSongComposerCard(ThemeData theme) {
    return FeedComposerCard(
      placeholderTemplate: 'Submit a song or hymn, {name}...',
      icon: Icons.queue_music_rounded,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubmitSongScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: const AdBannerWidget(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildSongComposerCard(theme),
                  ),
                ),
                if (_songs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 48,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Songs Found',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = _songs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SongDetailScreen(
                                      songs: _songs,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                song.title.isNotEmpty
                                                    ? song.title
                                                    : 'Untitled Song',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (song.author.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'By ${song.author}',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Trailing Chords Pill Badge
                                        if (song.hasChords)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: theme
                                                    .colorScheme
                                                    .secondary
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.music_note_rounded,
                                                  size: 14,
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Chords',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Content Preview
                                    Text(
                                      _getContentPreview(song.content),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        height: 1.4,
                                        color: theme.textTheme.bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _songs.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookmarksScreen()),
          );
        },
        icon: const Icon(Icons.bookmark_rounded),
        label: const Text('Bookmarks'),
      ),
    );
  }
}
