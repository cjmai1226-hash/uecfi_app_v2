import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post.dart';
import '../models/post_gradient.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../screens/features/public_profile_screen.dart';
import '../screens/features/profile_screen.dart';
import '../screens/features/create_post_screen.dart';
import 'user_avatar.dart';
import 'expandable_text.dart';
import 'contributor_badge.dart';

class CommunityPostCard extends StatefulWidget {
  final BlogPost post;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostDeleted;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  late BlogPost _post;
  final TextEditingController _commentInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(covariant CommunityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
  }

  @override
  void dispose() {
    _commentInputController.dispose();
    super.dispose();
  }

  void _openMemberProfile(
    BuildContext context,
    String authorName,
    String? avatarUrl, {
    String authorEmail = '',
  }) {
    final currentUser = UserService.instance.value;
    final isSelf = (authorEmail.isNotEmpty &&
            authorEmail.toLowerCase() == currentUser.email.toLowerCase()) ||
        authorName.toLowerCase() == currentUser.nickname.toLowerCase() ||
        '${currentUser.firstName} ${currentUser.lastName}'
                .trim()
                .toLowerCase() ==
            authorName.toLowerCase();

    if (isSelf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PublicProfileScreen(
            userEmail: authorEmail,
            initialNickname: authorName,
            initialAvatarUrl: avatarUrl,
          ),
        ),
      );
    }
  }

  void _showPostOptions(BuildContext context) {
    final theme = Theme.of(context);
    final profile = UserService.instance.value;
    final userNickname =
        profile.nickname.isNotEmpty ? profile.nickname : 'Member';
    final userFullName = '${profile.firstName} ${profile.lastName}'.trim();
    final isAuthor = _post.author == userNickname ||
        (userFullName.isNotEmpty && _post.author == userFullName) ||
        (_post.authorEmail.isNotEmpty &&
            _post.authorEmail.toLowerCase() == profile.email.toLowerCase());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isAuthor)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text(
                    'Edit Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CreatePostScreen(postToEdit: _post),
                      ),
                    );
                    widget.onPostUpdated?.call();
                  },
                ),
              ListTile(
                leading:
                    const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: const Text(
                  'Report Post',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showReportConfirmationDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showReportConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Post?'),
          content: Text(
            'Are you sure you want to report this post by "${_post.author}" for administrator review?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (_post.id is String) {
                  try {
                    await FirestoreService().reportPost(
                      postId: _post.id.toString(),
                      reason: 'Inappropriate content',
                      reportedBy: UserService.instance.value.email,
                    );
                    widget.onPostDeleted?.call();
                  } catch (e) {
                    debugPrint('Error reporting post in Firestore: $e');
                  }
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thank you. This post has been reported to the moderators.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _showCommentsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = UserService.instance.value;
    final userNickname =
        currentUser.nickname.isNotEmpty ? currentUser.nickname : 'Member';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _post.id is String
                          ? FirestoreService()
                              .getCommentsStream(_post.id.toString())
                          : null,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading comments: ${snapshot.error}',
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final comments = docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final ts = data['timestamp'] as Timestamp?;
                          final author =
                              data['authorNickname'] as String? ?? 'Member';
                          final directAvatar = data['avatarUrl'] as String?;
                          return PostComment(
                            id: doc.id,
                            author: author,
                            text: data['content'] ?? data['comment'] ?? '',
                            timeAgo: ts != null
                                ? BlogPost.formatTimestamp(ts)
                                : 'Just now',
                            avatarUrl: directAvatar,
                          );
                        }).toList();

                        if (comments.isEmpty) {
                          return Center(
                            child: Text(
                              'No comments yet. Be the first!',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final isCommentAuthor =
                                comment.author.toLowerCase() ==
                                    currentUser.nickname.toLowerCase();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _openMemberProfile(
                                      context,
                                      comment.author,
                                      comment.avatarUrl,
                                    ),
                                    child: UserAvatar(
                                      authorName: comment.author,
                                      localAvatarPath: isCommentAuthor
                                          ? currentUser.avatarPath
                                          : null,
                                      avatarUrl: isCommentAuthor &&
                                              (comment.avatarUrl == null ||
                                                  comment.avatarUrl!.isEmpty)
                                          ? currentUser.avatarUrl
                                          : comment.avatarUrl,
                                      radius: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2A2B2C)
                                            : const Color(0xFFEAEBED),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _openMemberProfile(
                                              context,
                                              comment.author,
                                              comment.avatarUrl,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  comment.author,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (comment.author
                                                        .toLowerCase() ==
                                                    'devchristian') ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.verified_rounded,
                                                    color: theme
                                                        .colorScheme.primary,
                                                    size: 13,
                                                  ),
                                                ],
                                                const SizedBox(width: 4),
                                                FutureBuilder<int>(
                                                  future: UserContributionsCache
                                                      .load(comment.author),
                                                  initialData:
                                                      UserContributionsCache
                                                              .get(
                                                            comment.author,
                                                          ) ??
                                                          0,
                                                  builder: (context, snapshot) {
                                                    final count =
                                                        snapshot.data ?? 0;
                                                    return getContributorBadge(
                                                      count,
                                                      theme,
                                                      size: 13,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment.text,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentInputController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2A2B2C)
                                  : const Color(0xFFEAEBED),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () async {
                            final text = _commentInputController.text.trim();
                            if (text.isEmpty) return;

                            _commentInputController.clear();
                            FocusScope.of(context).unfocus();

                            if (_post.id is String) {
                              try {
                                await FirestoreService().addComment(
                                  postId: _post.id.toString(),
                                  content: text,
                                  authorEmail: currentUser.email,
                                  authorNickname: userNickname,
                                  avatarUrl: currentUser.avatarUrl,
                                );
                                setState(() {
                                  _post.commentsCount++;
                                });
                                setModalState(() {});
                              } catch (e) {
                                debugPrint('Error adding comment: $e');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<UserProfile>(
      valueListenable: UserService.instance,
      builder: (context, profile, child) {
        final isAuthor =
            _post.author.toLowerCase() == profile.nickname.toLowerCase();
        final postGradient =
            PostGradientPreset.findById(_post.bgGradient);
        final isLong = _post.content.characters.length > 180 ||
            _post.content.split('\n').length > 4;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.6),
                width: 1,
              ),
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header (Avatar, Author, Badge, Time, Options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: GestureDetector(
                  onTap: () => _openMemberProfile(
                    context,
                    _post.author,
                    _post.avatarUrl,
                    authorEmail: _post.authorEmail,
                  ),
                  child: UserAvatar(
                    authorName: _post.author,
                    localAvatarPath: isAuthor ? profile.avatarPath : null,
                    avatarUrl: isAuthor &&
                            (_post.avatarUrl == null ||
                                _post.avatarUrl!.isEmpty)
                        ? profile.avatarUrl
                        : _post.avatarUrl,
                    radius: 20,
                  ),
                ),
                title: GestureDetector(
                  onTap: () => _openMemberProfile(
                    context,
                    _post.author,
                    _post.avatarUrl,
                    authorEmail: _post.authorEmail,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _post.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (_post.author.toLowerCase() == 'devchristian') ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ],
                      const SizedBox(width: 4),
                      FutureBuilder<int>(
                        future:
                            UserContributionsCache.load(_post.author),
                        initialData:
                            UserContributionsCache.get(_post.author) ?? 0,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return getContributorBadge(count, theme, size: 16);
                        },
                      ),
                    ],
                  ),
                ),
                subtitle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _post.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _post.isExpired
                          ? Icons.lock_outline_rounded
                          : Icons.public_rounded,
                      size: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => _showPostOptions(context),
                ),
              ),

              // Post Body Content
              if (postGradient != null && !isLong)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    gradient: postGradient.gradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _post.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ExpandableText(
                    text: _post.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Bottom Action Bar (Heart & Comments)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    // Like icon + count
                    InkWell(
                      onTap: () {
                        setState(() {
                          _post.isLiked = !_post.isLiked;
                          _post.likesCount += _post.isLiked ? 1 : -1;
                        });

                        if (_post.id is String) {
                          FirestoreService().togglePostLike(
                            _post.id.toString(),
                            !_post.isLiked,
                            profile.memberId,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _post.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 21,
                              color: _post.isLiked
                                  ? Colors.redAccent
                                  : theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_post.likesCount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Comment icon + count
                    InkWell(
                      onTap: () => _showCommentsBottomSheet(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_post.commentsCount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}
