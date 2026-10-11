import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../services/database_helper.dart';
import '../../models/song_model.dart';
import 'bookmarks_screen.dart';
import '../details/song_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_songs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            icon: HugeIcons.strokeRoundedMusic02,
                            size: 44,
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
                      delegate: SliverChildBuilderDelegate((context, index) {
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Song Title & Note Icon (if hasChords)
                                  Text.rich(
                                    TextSpan(
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                                  const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              child: AppIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedMusicNote01,
                                                size: 15,
                                                color: theme.colorScheme
                                                    .secondary,
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontSize: 13,
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: _songs.length),
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
        icon: const AppIcon(
          icon: HugeIcons.strokeRoundedBookmark02,
          size: 20,
          color: Colors.white,
        ),
        label: const Text('Bookmarks'),
      ),
    );
  }
}
