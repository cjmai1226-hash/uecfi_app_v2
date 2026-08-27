import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../main/home_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
    );

    // Insert at the top of the local fallback feed list
    HomeScreen.postsNotifier.value = [newPost, ...HomeScreen.postsNotifier.value];

    // Submit online to Firestore
    try {
      await FirestoreService().submitCommunityPost(
        content: postContent,
        authorEmail: profile.email,
        authorNickname: cleanAuthor,
      );
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    _submitPost(profile);
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'M';
        final hasPostContent = _controller.text.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Create Post'),
            actions: [
              TextButton(
                onPressed: hasPostContent ? () => _confirmSubmitPost(context, profile) : null,
                child: Text(
                  'Post',
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
          body: Column(
            children: [
              // User header row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      backgroundImage: nickname.toLowerCase() != 'devchristian' && profile.avatarPath.isNotEmpty
                          ? FileImage(File(profile.avatarPath))
                          : null,
                      child: nickname.toLowerCase() == 'devchristian'
                          ? Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/brand_mark.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : (profile.avatarPath.isEmpty
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null),
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

              // Editor TextField styled like SubmitSongScreen
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 6,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
