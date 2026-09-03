import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../models/blog_post.dart';
import '../../services/firestore_service.dart';
import '../main/home_screen.dart';
import '../../services/ad_service.dart';
import '../../models/post_gradient.dart';
import '../../widgets/user_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  final BlogPost? postToEdit;

  const CreatePostScreen({super.key, this.postToEdit});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _selectedGradientId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.postToEdit?.content ?? '');
    _selectedGradientId = widget.postToEdit?.bgGradient;
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitPost(UserProfile profile) async {
    final postContent = _controller.text.trim();
    if (postContent.isEmpty) return;

    final isPostTooLongForGradient =
        postContent.characters.length > 180 ||
        postContent.split('\n').length > 4;
    final effectiveGradientId =
        isPostTooLongForGradient ? null : _selectedGradientId;

    if (widget.postToEdit != null) {
      final editPost = widget.postToEdit!;
      // Update locally in fallback notifier list
      final currentList = List<BlogPost>.from(HomeScreen.postsNotifier.value);
      final idx = currentList.indexWhere((p) => p.id == editPost.id);
      if (idx != -1) {
        currentList[idx].content = postContent;
        currentList[idx].bgGradient = effectiveGradientId;
        HomeScreen.postsNotifier.value = currentList;
      }

      // Update online
      if (editPost.id is String) {
        try {
          await FirestoreService().updateCommunityPost(
            postId: editPost.id.toString(),
            newContent: postContent,
            previousContent: editPost.content,
            bgGradient: effectiveGradientId,
          );
        } catch (e) {
          debugPrint('Error updating post in Firestore: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(postContent);
      return;
    }

    final cleanAuthor = profile.nickname.isNotEmpty ? profile.nickname : 'Member';
    
    String roleText = profile.position.isNotEmpty ? profile.position : 'Member';
    if (profile.localCenter.isNotEmpty) {
      roleText += ' • ${profile.localCenter}';
    }

    final newPost = BlogPost(
      id: DateTime.now().millisecondsSinceEpoch,
      author: cleanAuthor,
      role: roleText,
      initials: profile.nickname.isNotEmpty ? profile.nickname[0].toUpperCase() : 'M',
      timeAgo: 'Just now',
      content: postContent,
      likesCount: 0,
      comments: [],
      bgGradient: effectiveGradientId,
      avatarUrl: profile.avatarUrl,
    );

    // Insert at the top of the local fallback feed list
    HomeScreen.postsNotifier.value = [newPost, ...HomeScreen.postsNotifier.value];

    // Submit online to Firestore
    try {
      await FirestoreService().submitCommunityPost(
        content: postContent,
        authorEmail: profile.email,
        authorNickname: cleanAuthor,
        bgGradient: effectiveGradientId,
        avatarUrl: profile.avatarUrl,
      );
      await FirestoreService().incrementUserContributions(profile.email);
    } catch (e) {
      debugPrint('Error submitting post to Firestore: $e');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post published successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  void _confirmSubmitPost(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Publish Notice'),
          ],
        ),
        content: const Text(
          'Please note: Your post will automatically expire and be removed from the home feed after 5 days.\n\nDo you want to proceed and publish?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    AdService().showDirectRewardedAd(
                      context: context,
                      onReward: () {
                        _submitPost(profile);
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Publish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile>(
      valueListenable: UserService.instance,
      builder: (context, profile, child) {
        final nickname = profile.nickname.isNotEmpty ? profile.nickname : 'Member';
        final hasPostContent = _controller.text.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.postToEdit != null ? 'Edit Post' : 'Create Post'),
            actions: [
              TextButton(
                onPressed: hasPostContent
                    ? () {
                        if (widget.postToEdit != null) {
                          _submitPost(profile);
                        } else {
                          _confirmSubmitPost(context, profile);
                        }
                      }
                    : null,
                child: Text(
                  widget.postToEdit != null ? 'Save' : 'Post',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasPostContent
                        ? (isDark ? theme.colorScheme.primary : const Color(0xFF1877F2))
                        : theme.disabledColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
            children: [
              // User header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    UserAvatar(
                      authorName: nickname,
                      localAvatarPath: profile.avatarPath,
                      avatarUrl: profile.avatarUrl,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public_rounded, size: 12, color: theme.textTheme.bodySmall?.color),
                              const SizedBox(width: 4),
                              Text(
                                'Public',
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Community Encouragement Subtext Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Share uplifting testimonies, daily prayers, announcements, or words of encouragement with the UECFI brethren!',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Editor TextField with dynamic Gradient Live Preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Builder(
                    builder: (context) {
                      final textChars = _controller.text.characters;
                      final isPostTooLongForGradient =
                          textChars.length > 180 ||
                          _controller.text.split('\n').length > 4;

                      final activePreset = !isPostTooLongForGradient
                          ? PostGradientPreset.findById(_selectedGradientId)
                          : null;

                      if (activePreset != null) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 28,
                              ),
                              decoration: BoxDecoration(
                                gradient: activePreset.gradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: activePreset.colors.first
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                maxLines: null,
                                textAlign: TextAlign.center,
                                cursorColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.45,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Type your message or prayer...",
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 6,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: widget.postToEdit != null
                              ? "Edit your post..."
                              : "What's on your mind?",
                          alignLabelWithHint: true,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Gradient Selector Horizontal Bar
              Builder(
                builder: (context) {
                  final textChars = _controller.text.characters;
                  final isPostTooLongForGradient =
                      textChars.length > 180 ||
                      _controller.text.split('\n').length > 4;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 16,
                              color: isPostTooLongForGradient
                                  ? theme.disabledColor
                                  : theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Background Color',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPostTooLongForGradient
                                    ? theme.disabledColor
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const Spacer(),
                            if (isPostTooLongForGradient)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Max 180 chars for backgrounds',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              )
                            else if (_selectedGradientId != null &&
                                _selectedGradientId != 'default')
                              Text(
                                '${textChars.length}/180',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: PostGradientPreset.presets.length,
                            separatorBuilder: (context, idx) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final preset = PostGradientPreset.presets[index];
                              final isSelected = (!isPostTooLongForGradient &&
                                      _selectedGradientId == null &&
                                      preset.id == 'default') ||
                                  (!isPostTooLongForGradient &&
                                      _selectedGradientId == preset.id);

                              if (preset.id == 'default') {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedGradientId = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF3A3B3C)
                                          : const Color(0xFFE4E6EB),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.dividerColor,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Aa',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return InkWell(
                                onTap: () {
                                  if (isPostTooLongForGradient) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Background styles are only available for messages under 180 characters.',
                                        ),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _selectedGradientId = preset.id;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Opacity(
                                  opacity: isPostTooLongForGradient ? 0.35 : 1.0,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: preset.gradient,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: preset.colors.first
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
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
  );
}
}
