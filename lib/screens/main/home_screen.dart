import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../forms/create_post_screen.dart';
import '../../models/blog_post.dart';
import '../../widgets/community_post_card.dart';
import '../history/uecfi_history_screen.dart';

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
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['isReported'] != true,
          )
          .map(
            (doc) => BlogPost.fromFirestore(
              doc,
              avatarMap: avatarMap,
              currentUserId: currentUserUid,
            ),
          )
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
                  // Heritage & Truth Featured Banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFE94057),
                            Color(0xFFF27121),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE94057).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UecfiHistoryScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Positioned(
                                right: -15,
                                bottom: -20,
                                child: AppIcon(
                                  icon: HugeIcons.strokeRoundedBookOpen01,
                                  size: 120,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.22),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppIcon(
                                                icon: HugeIcons.strokeRoundedSparkles,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'HERITAGE & TRUTH',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10.5,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Explore',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              AppIcon(
                                                icon: HugeIcons.strokeRoundedArrowRight01,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Discover Our Sacred Roots',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Explore the founding story, the brave pioneers of 1900, and church doctrines.',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        fontSize: 12.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Community Feed Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'Community Feed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  if (_isLoadingPosts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
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
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: AppIcon(
                                icon: HugeIcons.strokeRoundedNews,
                                size: 44,
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
                                icon: const AppIcon(
                                  icon: HugeIcons.strokeRoundedEdit02,
                                  size: 18,
                                  color: Colors.white,
                                ),
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
