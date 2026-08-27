import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _bookmarksKey = 'bookmarked_song_titles';

  /// Get list of bookmarked song titles
  static Future<List<String>> getBookmarkedSongTitles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarksKey) ?? [];
  }

  /// Check if a song title is bookmarked
  static Future<bool> isBookmarked(String title) async {
    if (title.trim().isEmpty) return false;
    final bookmarks = await getBookmarkedSongTitles();
    return bookmarks.contains(title);
  }

  /// Toggle bookmark status for a song title
  static Future<bool> toggleBookmark(String title) async {
    if (title.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    final isCurrentlyBookmarked = bookmarks.contains(title);
    if (isCurrentlyBookmarked) {
      bookmarks.remove(title);
    } else {
      bookmarks.add(title);
    }

    await prefs.setStringList(_bookmarksKey, bookmarks);
    return !isCurrentlyBookmarked;
  }
}
