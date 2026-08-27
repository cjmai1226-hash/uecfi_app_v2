class PrayerModel {
  final String title;
  final String title1;
  final String content;
  final String content1;
  final String category;
  final num? page;

  const PrayerModel({
    required this.title,
    required this.title1,
    required this.content,
    required this.content1,
    required this.category,
    this.page,
  });

  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      title: map['title']?.toString().trim() ?? '',
      title1: map['title1']?.toString().trim() ?? '',
      content: map['content']?.toString().trim() ?? '',
      content1: map['content1']?.toString().trim() ?? '',
      category: map['category']?.toString().trim() ?? '',
      page: map['page'] is num ? map['page'] as num : num.tryParse(map['page']?.toString() ?? ''),
    );
  }

  /// Get display title based on active language ('TAG' for Tagalog, default 'ILO' for Ilocano)
  String getDisplayTitle(String languageCode) {
    if (languageCode == 'TAG' && title1.isNotEmpty) {
      return title1;
    }
    return title.isNotEmpty ? title : title1;
  }

  /// Get display content based on active language ('TAG' for Tagalog, default 'ILO' for Ilocano)
  String getDisplayContent(String languageCode) {
    if (languageCode == 'TAG' && content1.isNotEmpty) {
      return content1;
    }
    return content.isNotEmpty ? content : content1;
  }
}
