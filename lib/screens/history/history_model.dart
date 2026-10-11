import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum TopicCategory {
  all('All Stories', HugeIcons.strokeRoundedSparkles),
  origins('Origins & Faith', HugeIcons.strokeRoundedSun02),
  freedom('Freedom & Struggle', HugeIcons.strokeRoundedFlag01),
  pioneers('Pioneers & Centers', HugeIcons.strokeRoundedUserGroup),
  mottos('Sacred Mottos', HugeIcons.strokeRoundedShieldCheck),
  timeline('Chronology', HugeIcons.strokeRoundedTimeline);

  final String label;
  final List<List<dynamic>> icon;
  const TopicCategory(this.label, this.icon);
}

class HistorySection {
  final String heading;
  final String body;
  final List<String>? bulletPoints;

  const HistorySection({
    required this.heading,
    required this.body,
    this.bulletPoints,
  });
}

class HistoryTopic {
  final String id;
  final String title;
  final String subtitle;
  final TopicCategory category;
  final int readTimeMinutes;
  final List<List<dynamic>> icon;
  final List<Color> gradientColors;
  final Color primaryColor;
  final String didYouKnow;
  final String summary;
  final List<HistorySection> sections;
  final List<String> keyScriptures;
  final String? quote;
  final String? quoteAuthor;

  const HistoryTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readTimeMinutes,
    required this.icon,
    required this.gradientColors,
    required this.primaryColor,
    required this.didYouKnow,
    required this.summary,
    required this.sections,
    this.keyScriptures = const [],
    this.quote,
    this.quoteAuthor,
  });
}

class TimelineEvent {
  final String year;
  final String title;
  final String description;
  final String badgeText;
  final List<Color> gradientColors;
  final List<List<dynamic>> icon;

  const TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.gradientColors,
    required this.icon,
  });
}
