import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../models/blog_post.dart';
import '../../services/firestore_service.dart';
import '../main/home_screen.dart';
import '../../services/ad_service.dart';
import '../../widgets/user_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  final BlogPost? postToEdit;
  final String? initialContent;

  const CreatePostScreen({super.key, this.postToEdit, this.initialContent});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.postToEdit?.content ?? widget.initialContent ?? '',
    );
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

  void _formatBold() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '**$selectedText**',
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + 2,
          extentOffset: selection.end + 2,
        ),
      );
    } else {
      final cursor = selection.isValid ? selection.start : text.length;
      const placeholder = 'bold text';
      final newText = text.replaceRange(cursor, cursor, '**$placeholder**');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursor + 2,
          extentOffset: cursor + 2 + placeholder.length,
        ),
      );
    }
    _focusNode.requestFocus();
  }

  void _formatItalic() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '*$selectedText*',
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + 1,
          extentOffset: selection.end + 1,
        ),
      );
    } else {
      final cursor = selection.isValid ? selection.start : text.length;
      const placeholder = 'italic text';
      final newText = text.replaceRange(cursor, cursor, '*$placeholder*');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursor + 1,
          extentOffset: cursor + 1 + placeholder.length,
        ),
      );
    }
    _focusNode.requestFocus();
  }

  void _formatBullet() {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    String insertText = '• ';
    if (cursor > 0 && text[cursor - 1] != '\n') {
      insertText = '\n• ';
    }

    final newText = text.replaceRange(
      cursor,
      selection.isValid ? selection.end : cursor,
      insertText,
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _focusNode.requestFocus();
  }

  void _formatNumbered() {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    int nextNumber = 1;
    if (cursor > 0) {
      final textBefore = text.substring(0, cursor);
      final lines = textBefore.split('\n');
      if (lines.isNotEmpty) {
        final lastLine = lines.last.trim();
        final match = RegExp(r'^(\d+)\.').firstMatch(lastLine);
        if (match != null) {
          nextNumber = (int.tryParse(match.group(1)!) ?? 0) + 1;
        } else if (lines.length > 1) {
          final prevLine = lines[lines.length - 2].trim();
          final matchPrev = RegExp(r'^(\d+)\.').firstMatch(prevLine);
          if (matchPrev != null) {
            nextNumber = (int.tryParse(matchPrev.group(1)!) ?? 0) + 1;
          }
        }
      }
    }

    String insertText = '$nextNumber. ';
    if (cursor > 0 && text[cursor - 1] != '\n') {
      insertText = '\n$nextNumber. ';
    }

    final newText = text.replaceRange(
      cursor,
      selection.isValid ? selection.end : cursor,
      insertText,
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _focusNode.requestFocus();
  }

  Widget _buildFormatButton({
    required BuildContext context,
    required List<List<dynamic>> icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: AppIcon(
              icon: icon,
              size: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  void _submitPost(UserProfile profile) async {
    final postContent = _controller.text.trim();
    if (postContent.isEmpty) return;

    if (widget.postToEdit != null) {
      final editPost = widget.postToEdit!;
      // Update locally in fallback notifier list
      final currentList = List<BlogPost>.from(HomeScreen.postsNotifier.value);
      final idx = currentList.indexWhere((p) => p.id == editPost.id);
      if (idx != -1) {
        currentList[idx].content = postContent;
        HomeScreen.postsNotifier.value = currentList;
      }

      // Update online
      if (editPost.id is String) {
        try {
          await FirestoreService().updateCommunityPost(
            postId: editPost.id.toString(),
            newContent: postContent,
            previousContent: editPost.content,
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

    final cleanAuthor = profile.nickname.isNotEmpty
        ? profile.nickname
        : 'Member';

    String roleText = profile.position.isNotEmpty ? profile.position : 'Member';
    if (profile.localCenter.isNotEmpty) {
      roleText += ' • ${profile.localCenter}';
    }

    final newPost = BlogPost(
      id: DateTime.now().millisecondsSinceEpoch,
      author: cleanAuthor,
      role: roleText,
      initials: profile.nickname.isNotEmpty
          ? profile.nickname[0].toUpperCase()
          : 'M',
      timeAgo: 'Just now',
      content: postContent,
      likesCount: 0,
      comments: [],
      avatarUrl: profile.avatarUrl,
    );

    // Insert at the top of the local fallback feed list
    HomeScreen.postsNotifier.value = [
      newPost,
      ...HomeScreen.postsNotifier.value,
    ];

    // Submit online to Firestore
    try {
      await FirestoreService().submitCommunityPost(
        content: postContent,
        authorEmail: profile.email,
        authorNickname: cleanAuthor,
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
        title: Row(
          children: [
            const AppIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: Colors.orangeAccent,
            ),
            const SizedBox(width: 8),
            const Text('Publish Notice'),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
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

    return ValueListenableBuilder<UserProfile>(
      valueListenable: UserService.instance,
      builder: (context, profile, child) {
        final nickname = profile.nickname.isNotEmpty
            ? profile.nickname
            : 'Member';
        final hasPostContent = _controller.text.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.postToEdit != null ? 'Edit Post' : 'Create Post',
            ),
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
                        ? theme.colorScheme.primary
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  icon: HugeIcons.strokeRoundedGlobal,
                                  size: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Public',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
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
                // Editor TextField
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 8,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15.5,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.postToEdit != null
                            ? "Edit your post..."
                            : "What's on your mind?",
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ),

                // Post Text Formatting Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildFormatButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedTextBold,
                        tooltip: 'Bold (**text**)',
                        onPressed: _formatBold,
                      ),
                      const SizedBox(width: 4),
                      _buildFormatButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedTextItalic,
                        tooltip: 'Italic (*text*)',
                        onPressed: _formatItalic,
                      ),
                      const SizedBox(width: 4),
                      _buildFormatButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedLeftToRightListBullet,
                        tooltip: 'Bullet List',
                        onPressed: _formatBullet,
                      ),
                      const SizedBox(width: 4),
                      _buildFormatButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedLeftToRightListNumber,
                        tooltip: 'Numbered List',
                        onPressed: _formatNumbered,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              icon: HugeIcons.strokeRoundedSparkles,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Markdown',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
