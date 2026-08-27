import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/center_model.dart';
import '../models/song_model.dart';
import '../models/prayer_model.dart';
import '../models/bylaw_model.dart';
import '../models/bible_verse_model.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String dbPath;
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      sqfliteFfiInit();
      dbPath = await databaseFactoryFfi.getDatabasesPath();
    } else {
      dbPath = await getDatabasesPath();
    }
    
    final path = join(dbPath, 'uecfi.db');

    // Ensure parent directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Copy prepopulated database from assets
    try {
      ByteData data = await rootBundle.load('assets/db/uecfi.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('Error copying uecfi.db from assets: $e');
    }

    if (isDesktop) {
      return await databaseFactoryFfi.openDatabase(path);
    }
    return await openDatabase(path);
  }

  /// Natural string comparison (e.g. District 1, District 2 ... District 19)
  static int compareNatural(String a, String b) {
    final regExp = RegExp(r'(\d+)');
    final matchA = regExp.firstMatch(a);
    final matchB = regExp.firstMatch(b);

    if (matchA != null && matchB != null) {
      final prefixA = a.substring(0, matchA.start);
      final prefixB = b.substring(0, matchB.start);
      if (prefixA == prefixB) {
        final numA = int.parse(matchA.group(1)!);
        final numB = int.parse(matchB.group(1)!);
        return numA.compareTo(numB);
      }
    }
    return a.compareTo(b);
  }

  /// Get distinct non-empty district names sorted naturally
  static Future<List<String>> getDistricts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT DISTINCT centerdistrict FROM Centers WHERE centerdistrict IS NOT NULL AND TRIM(centerdistrict) != ''",
      );
      final districts = maps.map((m) => m['centerdistrict'].toString().trim()).toList();
      districts.sort(compareNatural);
      return districts;
    } catch (e) {
      debugPrint('Error getting districts: $e');
      return [];
    }
  }

  /// Get centers filtered by district (or all if district is null/empty)
  static Future<List<CenterModel>> getCentersForDistrict(String? district) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps;
      if (district != null && district.isNotEmpty) {
        maps = await db.query(
          'Centers',
          where: 'centerdistrict = ?',
          whereArgs: [district],
          orderBy: 'centername ASC',
        );
      } else {
        maps = await db.query('Centers', orderBy: 'centername ASC');
      }
      return maps.map((m) => CenterModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting centers: $e');
      return [];
    }
  }

  /// Get all centers
  static Future<List<CenterModel>> getAllCenters() async {
    return getCentersForDistrict(null);
  }

  /// Get all songs from Songs table
  static Future<List<SongModel>> getAllSongs() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Songs',
        orderBy: 'title ASC',
      );
      return maps.map((m) => SongModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting songs: $e');
      return [];
    }
  }

  /// Get all prayers from Prayers table ordered by page number
  static Future<List<PrayerModel>> getAllPrayers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Prayers',
        orderBy: 'page ASC, title ASC',
      );
      return maps.map((m) => PrayerModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting prayers: $e');
      return [];
    }
  }

  /// Get all bylaws from bylaws table ordered by chapter
  static Future<List<BylawModel>> getAllBylaws() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'bylaws',
        orderBy: 'chapters ASC, title ASC',
      );
      return maps.map((m) => BylawModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting bylaws: $e');
      return [];
    }
  }

  /// Get distinct books from ILODOR table ordered by ROWID
  static Future<List<Map<String, String>>> getBibleBooks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT DISTINCT book_id, book_name FROM ILODOR ORDER BY ROWID",
      );
      return maps.map((m) => {
        'book_id': m['book_id']?.toString() ?? '',
        'book_name': m['book_name']?.toString() ?? '',
      }).toList();
    } catch (e) {
      debugPrint('Error getting bible books: $e');
      return [];
    }
  }

  /// Get number of chapters in a book
  static Future<int> getBibleChaptersCount(String bookId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT MAX(chapter) as max_chapter FROM ILODOR WHERE book_id = ?",
        [bookId],
      );
      if (maps.isNotEmpty && maps.first['max_chapter'] != null) {
        return maps.first['max_chapter'] as int;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting bible chapters count: $e');
      return 0;
    }
  }

  /// Get all verses for a given book and chapter
  static Future<List<BibleVerseModel>> getBibleVerses(String bookId, int chapter) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ILODOR',
        where: 'book_id = ? AND chapter = ?',
        whereArgs: [bookId, chapter],
        orderBy: 'verse ASC',
      );
      return maps.map((m) => BibleVerseModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting bible verses: $e');
      return [];
    }
  }

  /// Search the ILODOR bible for a query string
  static Future<List<BibleVerseModel>> searchBible(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ILODOR',
        where: 'text LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'ROWID',
        limit: 100,
      );
      return maps.map((m) => BibleVerseModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error searching bible: $e');
      return [];
    }
  }
}
