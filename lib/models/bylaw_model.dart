class BylawModel {
  final int? chapters;
  final String title;
  final String content;

  const BylawModel({
    this.chapters,
    required this.title,
    required this.content,
  });

  String get chapterTag => chapters != null ? 'CH.$chapters' : '';

  factory BylawModel.fromMap(Map<String, dynamic> map) {
    int? parsedChapter;
    if (map['chapters'] != null) {
      if (map['chapters'] is int) {
        parsedChapter = map['chapters'] as int;
      } else {
        parsedChapter = int.tryParse(map['chapters'].toString());
      }
    }

    return BylawModel(
      chapters: parsedChapter,
      title: map['title']?.toString().trim() ?? '',
      content: map['content']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapters': chapters,
      'title': title,
      'content': content,
    };
  }
}
