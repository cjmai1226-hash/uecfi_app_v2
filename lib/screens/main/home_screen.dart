import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feed_composer_card.dart';
import '../../widgets/expandable_text.dart';
import '../features/create_post_screen.dart';
import '../../widgets/contributor_badge.dart';
import '../../models/post_gradient.dart';

class BlogPost {
  final dynamic id;
  final String author;
  final String role;
  final String initials;
  final String timeAgo;
  String content;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool showComments;
  final List<PostComment> comments;
  String? bgGradient;

  BlogPost({
    required this.id,
    required this.author,
    required this.role,
    required this.initials,
    required this.timeAgo,
    required this.content,
    required this.likesCount,
    this.commentsCount = 0,
    this.isLiked = false,
    this.showComments = false,
    required this.comments,
    this.bgGradient,
  });
}

class PostComment {
  final dynamic id;
  final String author;
  String text;
  final String timeAgo;

  PostComment({
    this.id,
    required this.author,
    required this.text,
    required this.timeAgo,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final ValueNotifier<List<BlogPost>> postsNotifier = ValueNotifier<List<BlogPost>>([]);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<dynamic, TextEditingController> _commentControllers = {};
  List<BlogPost> _posts = [];
  bool _isLoadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }


  Future<void> _fetchPosts() async {
    if (_posts.isEmpty) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final snapshot = await FirestoreService().getCommunityPosts();
      final docs = snapshot.docs;
      final fetchedPosts = docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isReported'] != true)
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final likedBy = data['likedBy'] as List<dynamic>? ?? [];
        final currentUserUid = UserService.instance.value.memberId;
        final timestamp = data['timestamp'] as Timestamp?;
        
        return BlogPost(
          id: doc.id,
          author: data['authorNickname'] ?? 'Member',
          role: 'Member',
          initials: (data['authorNickname'] as String?)?.isNotEmpty == true
              ? data['authorNickname'][0].toUpperCase()
              : 'M',
          timeAgo: timestamp != null
              ? _formatTimestamp(timestamp)
              : 'Just now',
          content: data['content'] ?? '',
          likesCount: data['likes'] as int? ?? 0,
          commentsCount: data['comments'] as int? ?? 0,
          isLiked: likedBy.contains(currentUserUid),
          comments: [],
          bgGradient: data['bgGradient'] as String?,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _posts = fetchedPosts;
          _isLoadingPosts = false;
        });
        _updateCommentControllers();
      }
    } catch (e) {
      debugPrint('Error fetching community posts: $e');
      if (mounted) {
        setState(() {
          _postsError = e.toString();
          _isLoadingPosts = false;
        });
      }
    }
  }

  void _showCommentOptionsBottomSheet({
    required BuildContext context,
    required BlogPost post,
    required PostComment comment,
    required StateSetter parentSetModalState,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Comment'),
                onTap: () {
                  Navigator.pop(context); // Close options sheet
                  _showEditCommentDialog(
                    context: context,
                    post: post,
                    comment: comment,
                    parentSetModalState: parentSetModalState,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Comment', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close options sheet
                  _confirmDeleteComment(
                    context: context,
                    post: post,
                    comment: comment,
                    parentSetModalState: parentSetModalState,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCommentDialog({
    required BuildContext context,
    required BlogPost post,
    required PostComment comment,
    required StateSetter parentSetModalState,
  }) {
    final editController = TextEditingController(text: comment.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: 'Enter comment...',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  if (comment.id != null) {
                    try {
                      await FirestoreService().updateComment(
                        post.id.toString(),
                        comment.id.toString(),
                        newText,
                      );
                    } catch (e) {
                      debugPrint('Error updating comment in Firestore: $e');
                    }
                  } else {
                    setState(() {
                      comment.text = newText;
                    });
                    HomeScreen.postsNotifier.value = List.from(HomeScreen.postsNotifier.value);
                  }
                  parentSetModalState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteComment({
    required BuildContext context,
    required BlogPost post,
    required PostComment comment,
    required StateSetter parentSetModalState,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (comment.id != null) {
                  try {
                    await FirestoreService().deleteComment(
                      post.id.toString(),
                      comment.id.toString(),
                    );
                    setState(() {
                      post.commentsCount = (post.commentsCount - 1).clamp(0, 9999);
                    });
                  } catch (e) {
                    debugPrint('Error deleting comment from Firestore: $e');
                  }
                } else {
                  setState(() {
                    post.comments.remove(comment);
                  });
                }
                parentSetModalState(() {});
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _updateCommentControllers() {
    for (var post in _posts) {
      if (!_commentControllers.containsKey(post.id)) {
        _commentControllers[post.id] = TextEditingController();
      }
    }
  }


  void _handleLike(BlogPost post) async {
    final originalIsLiked = post.isLiked;
    final originalLikesCount = post.likesCount;

    setState(() {
      if (post.isLiked) {
        post.isLiked = false;
        post.likesCount--;
      } else {
        post.isLiked = true;
        post.likesCount++;
      }
    });

    if (post.id is String) {
      try {
        await FirestoreService().togglePostLike(
          post.id.toString(),
          originalIsLiked,
          UserService.instance.value.memberId,
        );
      } catch (e) {
        debugPrint('Error toggling like in Firestore: $e');
        setState(() {
          post.isLiked = originalIsLiked;
          post.likesCount = originalLikesCount;
        });
      }
    }
  }

  void _showCommentsBottomSheet(BuildContext context, BlogPost post, String userNickname) {
    final controller = _commentControllers[post.id] ?? TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment list inside a constrained scroll area
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: (post.id is String)
                        ? StreamBuilder<QuerySnapshot>(
                            stream: FirestoreService().getCommentsStream(post.id.toString()),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No comments yet. Be the first to comment!',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                );
                              }
                              final commentsList = docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final timestamp = data['timestamp'] as Timestamp?;
                                return PostComment(
                                  id: doc.id,
                                  author: data['authorNickname'] ?? 'Member',
                                  text: data['content'] ?? '',
                                  timeAgo: timestamp != null
                                      ? _formatTimestamp(timestamp)
                                      : 'Just now',
                                );
                              }).toList();

                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: commentsList.length,
                                itemBuilder: (context, index) {
                                  final comment = commentsList[index];
                                  return GestureDetector(
                                    onLongPress: () {
                                      if (comment.author != userNickname) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('You can only edit or delete your own comments.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                      _showCommentOptionsBottomSheet(
                                        context: context,
                                        post: post,
                                        comment: comment,
                                        parentSetModalState: setModalState,
                                      );
                                    },
                                    child: _buildCommentItem(theme, comment, isDark),
                                  );
                                },
                              );
                            },
                          )
                        : (post.comments.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No comments yet. Be the first to comment!',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: post.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = post.comments[index];
                                  return GestureDetector(
                                    onLongPress: () {
                                      if (comment.author != userNickname) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('You can only edit or delete your own comments.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                      _showCommentOptionsBottomSheet(
                                        context: context,
                                        post: post,
                                        comment: comment,
                                        parentSetModalState: setModalState,
                                      );
                                    },
                                    child: _buildCommentItem(theme, comment, isDark),
                                  );
                                },
                              )),
                  ),
                  const SizedBox(height: 12),

                  // Comment Input
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFEAEBED),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          textInputAction: TextInputAction.send,
                          onFieldSubmitted: (val) async {
                            if (controller.text.trim().isEmpty) return;
                            final text = controller.text.trim();
                            setModalState(() {
                              controller.clear();
                            });

                            if (post.id is String) {
                              try {
                                await FirestoreService().addComment(
                                  postId: post.id.toString(),
                                  content: text,
                                  authorEmail: UserService.instance.value.email,
                                  authorNickname: userNickname,
                                );
                                setState(() {
                                  post.commentsCount++;
                                });
                              } catch (e) {
                                debugPrint('Error adding comment to Firestore: $e');
                              }
                            } else {
                              setState(() {
                                post.comments.add(
                                  PostComment(
                                    author: userNickname,
                                    text: text,
                                    timeAgo: 'Just now',
                                  ),
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) return;
                          final text = controller.text.trim();
                          setModalState(() {
                            controller.clear();
                          });

                          if (post.id is String) {
                            try {
                              await FirestoreService().addComment(
                                postId: post.id.toString(),
                                content: text,
                                authorEmail: UserService.instance.value.email,
                                authorNickname: userNickname,
                              );
                              setState(() {
                                post.commentsCount++;
                              });
                            } catch (e) {
                              debugPrint('Error adding comment to Firestore: $e');
                            }
                          } else {
                            setState(() {
                              post.comments.add(
                                PostComment(
                                  author: userNickname,
                                  text: text,
                                  timeAgo: 'Just now',
                                ),
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(ThemeData theme, PostComment comment, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: comment.author.toLowerCase() == 'devchristian'
                ? Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/brand_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : Text(
                    comment.author.isNotEmpty ? comment.author[0].toUpperCase() : 'M',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFEAEBED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        comment.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (comment.author.toLowerCase() == 'devchristian') ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: theme.colorScheme.primary,
                          size: 13,
                        ),
                      ],
                      const SizedBox(width: 4),
                      FutureBuilder<int>(
                        future: UserContributionsCache.load(comment.author),
                        initialData: UserContributionsCache.get(comment.author) ?? 0,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return getContributorBadge(count, theme, size: 13);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
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

  void _showPostOptions(BuildContext context, BlogPost post) {
    final theme = Theme.of(context);
    final profile = UserService.instance.value;
    final userNickname = profile.nickname.isNotEmpty ? profile.nickname : 'Member';
    final userFullName = '${profile.firstName} ${profile.lastName}'.trim();
    final isAuthor = post.author == userNickname ||
        (userFullName.isNotEmpty && post.author == userFullName);

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
                  title: const Text('Edit Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final updatedContent = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(postToEdit: post),
                      ),
                    );
                    if (updatedContent != null) {
                      setState(() {
                        post.content = updatedContent;
                      });
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: const Text('Report Post', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showReportConfirmationDialog(context, post);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }



  void _showReportConfirmationDialog(BuildContext context, BlogPost post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Post?'),
          content: Text('Are you sure you want to report this post by "${post.author}" for administrator review?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (post.id is String) {
                  try {
                    await FirestoreService().reportPost(
                      postId: post.id.toString(),
                      reason: 'Inappropriate content',
                      reportedBy: UserService.instance.value.email,
                    );
                    setState(() {
                      _posts.removeWhere((p) => p.id == post.id);
                    });
                  } catch (e) {
                    debugPrint('Error reporting post in Firestore: $e');
                  }
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you. This post has been reported to the moderators.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ValueListenableBuilder<UserProfile>(
        valueListenable: UserService.instance,
        builder: (context, profile, child) {
          return RefreshIndicator(
            onRefresh: _fetchPosts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Composer Card (Edge-to-Edge)
                  FeedComposerCard(
                    placeholderTemplate: "What's on your mind, {name}?",
                    icon: Icons.send_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePostScreen(),
                        ),
                      ).then((_) => _fetchPosts());
                    },
                  ),

                  // Community Feed Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Text(
                      'Community Feed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (_isLoadingPosts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_postsError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Center(
                        child: Text(
                          'Error loading posts. Pull down to try again.',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    )
                  else if (_posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.feed_outlined,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nothing to see here right now',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to share something with the community!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CreatePostScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_note_rounded),
                                label: const Text(
                                  'Create a post now',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            border: Border(
                              top: BorderSide(
                                color: theme.dividerColor
                                    .withValues(alpha: 0.6),
                                width: 1,
                              ),
                              bottom: BorderSide(
                                color: theme.dividerColor
                                    .withValues(alpha: 0.8),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Post Header (Avatar, Author, Position, Time, Options)
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  child: post.author.toLowerCase() ==
                                          'devchristian'
                                      ? Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/brand_mark.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          post.initials,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      post.author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (post.author.toLowerCase() ==
                                        'devchristian') ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.verified_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 16,
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    FutureBuilder<int>(
                                      future: UserContributionsCache.load(
                                        post.author,
                                      ),
                                      initialData:
                                          UserContributionsCache.get(
                                                post.author,
                                              ) ??
                                              0,
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        return getContributorBadge(
                                          count,
                                          theme,
                                          size: 16,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      post.timeAgo,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.public_rounded,
                                      size: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  tooltip: 'Post options',
                                  onPressed: () =>
                                      _showPostOptions(context, post),
                                ),
                              ),

                              // Post Content (Edge-to-edge if short gradient, padded if standard/long)
                              Builder(
                                builder: (context) {
                                  final postGradient =
                                      PostGradientPreset.findById(
                                    post.bgGradient,
                                  );
                                  final isLongPost =
                                      post.content.characters.length > 180 ||
                                      post.content.split('\n').length > 4;

                                  if (postGradient != null && !isLongPost) {
                                    return Container(
                                      width: double.infinity,
                                      constraints:
                                          const BoxConstraints(minHeight: 180),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 36,
                                      ),
                                      margin: const EdgeInsets.only(
                                        top: 2,
                                        bottom: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: postGradient.gradient,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        post.content,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.45,
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: ExpandableText(
                                      text: post.content,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  bottom: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Like icon + count
                                    InkWell(
                                      onTap: () => _handleLike(post),
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
                                              post.isLiked
                                                  ? Icons.favorite_rounded
                                                  : Icons
                                                      .favorite_border_rounded,
                                              size: 16,
                                              color: post.isLiked
                                                  ? Colors.red
                                                  : theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${post.likesCount}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: post.isLiked
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: post.isLiked
                                                    ? Colors.red
                                                    : theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Comment icon + count
                                    InkWell(
                                      onTap: () => _showCommentsBottomSheet(
                                        context,
                                        post,
                                        profile.nickname,
                                      ),
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
                                              Icons.mode_comment_outlined,
                                              size: 16,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${post.id is String ? post.commentsCount : post.comments.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
