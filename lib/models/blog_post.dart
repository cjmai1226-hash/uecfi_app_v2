import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  final dynamic id;
  final String author;
  final String role;
  final String initials;
  final String timeAgo;
  final DateTime? timestamp;
  String content;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool showComments;
  final List<PostComment> comments;
  String? bgGradient;
  final String? avatarUrl;
  final String authorEmail;

  bool get isExpired {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp!).inDays >= 5;
  }

  BlogPost({
    required this.id,
    required this.author,
    required this.role,
    required this.initials,
    required this.timeAgo,
    this.timestamp,
    required this.content,
    required this.likesCount,
    this.commentsCount = 0,
    this.isLiked = false,
    this.showComments = false,
    required this.comments,
    this.bgGradient,
    this.avatarUrl,
    this.authorEmail = '',
  });

  factory BlogPost.fromFirestore(
    DocumentSnapshot doc, {
    Map<String, String>? avatarMap,
    String? currentUserId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final likedBy = data['likedBy'] as List<dynamic>? ?? [];
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate();
    final authorNickname = data['authorNickname'] as String? ?? 'Member';
    final authorEmail = (data['authorEmail'] as String?)?.toLowerCase() ?? '';

    final directAvatar = data['avatarUrl'] as String?;
    final resolvedAvatar = (directAvatar != null && directAvatar.isNotEmpty)
        ? directAvatar
        : (avatarMap != null
            ? (avatarMap[authorEmail] ?? avatarMap[authorNickname.toLowerCase()])
            : null);

    return BlogPost(
      id: doc.id,
      author: authorNickname,
      role: 'Member',
      initials: authorNickname.isNotEmpty
          ? authorNickname[0].toUpperCase()
          : 'M',
      timeAgo: timestamp != null
          ? formatTimestamp(timestamp)
          : 'Just now',
      timestamp: dateTime,
      content: data['content'] ?? '',
      likesCount: data['likes'] as int? ?? 0,
      commentsCount: data['comments'] as int? ?? 0,
      isLiked: currentUserId != null && likedBy.contains(currentUserId),
      comments: [],
      bgGradient: data['bgGradient'] as String?,
      avatarUrl: resolvedAvatar,
      authorEmail: authorEmail,
    );
  }

  factory BlogPost.fromMap(
    Map<String, dynamic> data, {
    String? currentUserId,
    String? fallbackAvatarUrl,
  }) {
    final likedBy = data['likedBy'] as List<dynamic>? ?? [];
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate();
    final authorNickname = data['authorNickname'] as String? ?? 'Member';
    final authorEmail = (data['authorEmail'] as String?)?.toLowerCase() ?? '';
    final directAvatar = data['avatarUrl'] as String?;
    final resolvedAvatar = (fallbackAvatarUrl != null && fallbackAvatarUrl.isNotEmpty)
        ? fallbackAvatarUrl
        : directAvatar;

    return BlogPost(
      id: data['id'] ?? '',
      author: authorNickname,
      role: 'Member',
      initials: authorNickname.isNotEmpty
          ? authorNickname[0].toUpperCase()
          : 'M',
      timeAgo: timestamp != null
          ? formatTimestamp(timestamp)
          : 'Just now',
      timestamp: dateTime,
      content: data['content'] ?? '',
      likesCount: data['likes'] as int? ?? 0,
      commentsCount: data['comments'] as int? ?? 0,
      isLiked: currentUserId != null && likedBy.contains(currentUserId),
      comments: [],
      bgGradient: data['bgGradient'] as String?,
      avatarUrl: resolvedAvatar,
      authorEmail: authorEmail,
    );
  }

  static String formatTimestamp(Timestamp timestamp) {
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      final date = timestamp.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class PostComment {
  final dynamic id;
  final String author;
  String text;
  final String timeAgo;
  final String? avatarUrl;

  PostComment({
    this.id,
    required this.author,
    required this.text,
    required this.timeAgo,
    this.avatarUrl,
  });
}
