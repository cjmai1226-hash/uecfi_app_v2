import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../widgets/feed_composer_card.dart';
import '../features/create_post_screen.dart';
import '../../models/blog_post.dart';
import '../../widgets/community_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final ValueNotifier<List<BlogPost>> postsNotifier =
      ValueNotifier<List<BlogPost>>([]);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BlogPost> _posts = [];
  bool _isLoadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (_posts.isEmpty) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final postsFuture = FirestoreService().getCommunityPosts();
      final usersFuture = FirebaseFirestore.instance.collection('users').get();

      final results = await Future.wait([postsFuture, usersFuture]);
      final snapshot = results[0];
      final usersSnapshot = results[1];

      final Map<String, String> avatarMap = {};
      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final avatar = data['avatarUrl'] as String?;
        if (avatar != null && avatar.isNotEmpty) {
          avatarMap[doc.id.toLowerCase()] = avatar;
          final email = data['email'] as String?;
          if (email != null && email.isNotEmpty) {
            avatarMap[email.toLowerCase()] = avatar;
          }
          final name = data['name'] as String?;
          if (name != null && name.isNotEmpty) {
            avatarMap[name.toLowerCase()] = avatar;
          }
        }
      }

      final docs = snapshot.docs;
      final currentUserUid = UserService.instance.value.memberId;
      final fetchedPosts = docs
          .where((doc) =>
              (doc.data() as Map<String, dynamic>)['isReported'] != true)
          .map((doc) => BlogPost.fromFirestore(
                doc,
                avatarMap: avatarMap,
                currentUserId: currentUserUid,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _posts = fetchedPosts;
          _isLoadingPosts = false;
        });
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
                        return CommunityPostCard(
                          post: post,
                          onPostUpdated: _fetchPosts,
                          onPostDeleted: () {
                            setState(() {
                              _posts.removeWhere((p) => p.id == post.id);
                            });
                          },
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
