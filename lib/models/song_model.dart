class SongModel {
  final String title;
  final String content;
  final String chords;
  final String category;
  final String author;

  const SongModel({
    required this.title,
    required this.content,
    required this.chords,
    required this.category,
    required this.author,
  });

  bool get hasChords => chords.trim().isNotEmpty;

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      title: map['title']?.toString().trim() ?? '',
      content: map['content']?.toString().trim() ?? '',
      chords: map['chords']?.toString().trim() ?? '',
      category: map['category']?.toString().trim() ?? '',
      author: map['author']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'chords': chords,
      'category': category,
      'author': author,
    };
  }
}
