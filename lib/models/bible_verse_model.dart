class BibleVerseModel {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String? footnotes;

  const BibleVerseModel({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    this.footnotes,
  });

  factory BibleVerseModel.fromMap(Map<String, dynamic> map) {
    return BibleVerseModel(
      bookId: map['book_id']?.toString() ?? '',
      bookName: map['book_name']?.toString() ?? '',
      chapter: map['chapter'] is int ? map['chapter'] : int.tryParse(map['chapter']?.toString() ?? '') ?? 0,
      verse: map['verse'] is int ? map['verse'] : int.tryParse(map['verse']?.toString() ?? '') ?? 0,
      text: map['text']?.toString() ?? '',
      footnotes: map['footnotes']?.toString(),
    );
  }
}
