import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/community_post_card.dart';
import '../../models/blog_post.dart';
import '../../services/user_service.dart';
import '../../services/firestore_service.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userEmail;
  final String? initialNickname;
  final String? initialAvatarUrl;
  final String? initialLocalCenter;

  const PublicProfileScreen({
    super.key,
    required this.userEmail,
    this.initialNickname,
    this.initialAvatarUrl,
    this.initialLocalCenter,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<BlogPost> _userPosts = [];
  List<Map<String, dynamic>> _contributions = [];
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _fetchMemberProfile();
  }

  Future<void> _fetchMemberProfile() async {
    final cleanEmail = widget.userEmail.trim().toLowerCase();

    try {
      DocumentSnapshot? doc;
      if (cleanEmail.isNotEmpty && cleanEmail.contains('@')) {
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cleanEmail)
            .get();
      }

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        // Fallback search by nickname if email not provided/matched
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: widget.initialNickname ?? '')
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          setState(() {
            _userData = query.docs.first.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _userData = {
              'name': widget.initialNickname ?? 'Member',
              'avatarUrl': widget.initialAvatarUrl,
              'centerName': widget.initialLocalCenter ?? '',
              'isLocked': false,
            };
            _isLoading = false;
          });
        }
      }

      // Fetch member contributions breakdown
      if (cleanEmail.isNotEmpty) {
        try {
          final items = await FirestoreService().getUserContributions(
            cleanEmail,
          );
          if (mounted) {
            setState(() {
              _contributions = items;
            });
          }
        } catch (_) {}
      }

      // If unlocked, fetch their public posts
      final bool isLocked = _userData?['isLocked'] == true;
      if (!isLocked) {
        _fetchUserPosts();
      }
    } catch (e) {
      debugPrint('Error fetching member profile: $e');
      setState(() {
        _userData = {
          'name': widget.initialNickname ?? 'Member',
          'avatarUrl': widget.initialAvatarUrl,
          'centerName': widget.initialLocalCenter ?? '',
          'isLocked': false,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserPosts() async {
    setState(() => _isLoadingPosts = true);
    final cleanEmail = widget.userEmail.trim().toLowerCase();
    final name = (_userData?['name'] ?? widget.initialNickname ?? '').trim();

    try {
      // Fetch community posts without composite index requirement
      final snapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final memberAvatarUrl =
          _userData?['avatarUrl'] as String? ?? widget.initialAvatarUrl;

      final posts = snapshot.docs
          .where((d) {
            final data = d.data();
            final isReported = data['isReported'] == true;
            final type = data['type']?.toString().toLowerCase();
            final isSong = type == 'song' || type == 'song_submission';
            final isCenter = type == 'center' || type == 'center_update';
            if (isReported || isSong || isCenter) return false;

            final postEmail =
                (data['authorEmail'] as String?)?.trim().toLowerCase() ?? '';
            final postNickname =
                (data['authorNickname'] as String?)?.trim().toLowerCase() ?? '';

            final bool matchEmail =
                cleanEmail.isNotEmpty && postEmail == cleanEmail;
            final bool matchNickname =
                name.isNotEmpty && postNickname == name.toLowerCase();

            return matchEmail || matchNickname;
          })
          .map((d) {
            final data = d.data();
            data['id'] = d.id;
            return BlogPost.fromMap(
              data,
              currentUserId: UserService.instance.value.memberId,
              fallbackAvatarUrl: memberAvatarUrl,
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching member posts: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  void _showFullScreenImageViewer(
    BuildContext context, {
    required String imageUrl,
    required String title,
  }) {
    if (imageUrl.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const AppIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        icon: HugeIcons.strokeRoundedImage01,
                        color: Colors.white54,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Unable to load photo',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = UserService.instance.value;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile'), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String displayName =
        _userData?['name'] ?? widget.initialNickname ?? 'Member';
    final String? avatarUrl =
        _userData?['avatarUrl'] ?? widget.initialAvatarUrl;
    final String? coverUrl = _userData?['coverUrl'];

    final String rawDistrict = _userData?['district'] ?? '';
    final String district = rawDistrict.isNotEmpty
        ? (rawDistrict.startsWith('District')
              ? rawDistrict
              : 'District $rawDistrict')
        : '';

    final String rawArea = _userData?['area'] ?? '';
    final String area = rawArea.isNotEmpty
        ? (rawArea.startsWith('Area') ? rawArea : 'Area $rawArea')
        : '';

    final String localCenter =
        _userData?['centerName'] ??
        _userData?['localCenter'] ??
        widget.initialLocalCenter ??
        '';
    final String centerAddress = _userData?['centerAddress'] ?? '';
    final String position = _userData?['position'] ?? 'Member';
    final bool isLocked = _userData?['isLocked'] == true;

    final bool isSelf =
        (widget.userEmail.isNotEmpty &&
            widget.userEmail.toLowerCase() ==
                currentUser.email.toLowerCase()) ||
        displayName.toLowerCase() == currentUser.nickname.toLowerCase();
    final bool isDevChristian = displayName.toLowerCase() == 'devchristian';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const AppIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 22,
            ),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facebook-style Cover & Avatar Header (Matching ProfileScreen)
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover photo container
                GestureDetector(
                  onTap: coverUrl != null && coverUrl.isNotEmpty
                      ? () => _showFullScreenImageViewer(
                          context,
                          imageUrl: coverUrl,
                          title: '$displayName\'s Cover Photo',
                        )
                      : null,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: coverUrl == null || coverUrl.isEmpty
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.8,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      image: coverUrl != null && coverUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(coverUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                ),

                // Overlapping Profile Avatar
                Positioned(
                  bottom: -60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: avatarUrl != null && avatarUrl.isNotEmpty
                          ? () => _showFullScreenImageViewer(
                              context,
                              imageUrl: avatarUrl,
                              title: '$displayName\'s Profile Photo',
                            )
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 4.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: UserAvatar(
                          authorName: displayName,
                          avatarUrl: avatarUrl,
                          radius: 64,
                          borderRadius: BorderRadius.circular(28),
                          backgroundColor: isDark
                              ? const Color(0xFF3A3B3C)
                              : const Color(0xFFE4E6EB),
                          textStyle: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70), // Spacer for overlapping avatar
            // Centered Name, Badges & Subtitle Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Nickname and badges
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isDevChristian) ...[
                          const SizedBox(width: 6),
                          AppIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Centered contributions breakdown subtitle
                  Builder(
                    builder: (context) {
                      final int postCount = _contributions
                          .where(
                            (item) =>
                                (item['type'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('post') &&
                                item['status'] != 'reported',
                          )
                          .length;
                      final int songCount = _contributions
                          .where(
                            (item) =>
                                (item['type'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('song') &&
                                item['status'] != 'reported',
                          )
                          .length;
                      final int centerCount = _contributions
                          .where(
                            (item) =>
                                (item['type'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('center') &&
                                item['status'] != 'reported',
                          )
                          .length;

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: '$postCount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                TextSpan(
                                  text: postCount == 1
                                      ? ' post • '
                                      : ' posts • ',
                                ),
                                TextSpan(
                                  text: '$songCount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                TextSpan(
                                  text: songCount == 1
                                      ? ' song submitted • '
                                      : ' songs submitted • ',
                                ),
                                TextSpan(
                                  text: '$centerCount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                TextSpan(
                                  text: centerCount == 1
                                      ? ' center update'
                                      : ' center updates',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  // If user is visiting their own profile
                  if (isSelf) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        icon: AppIcon(
                          icon: HugeIcons.strokeRoundedEdit02,
                          size: 18,
                          color: isDark
                              ? const Color(0xFFE4E6EB)
                              : const Color(0xFF050505),
                        ),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF3A3B3C)
                              : const Color(0xFFE4E6EB),
                          foregroundColor: isDark
                              ? const Color(0xFFE4E6EB)
                              : const Color(0xFF050505),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // LOCKED PROFILE VIEW
                  if (isLocked) ...[
                    Card(
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber.withValues(alpha: 0.12),
                              ),
                              child: const AppIcon(
                                icon: HugeIcons.strokeRoundedLockKeyhole,
                                size: 36,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Profile Locked',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This member has locked their profile to maintain privacy. Personal details and recent posts are protected.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]
                  // UNLOCKED / PUBLIC PROFILE VIEW
                  else ...[
                    // Personal Details Section
                    Text(
                      'Personal Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                          if (position.isNotEmpty) ...[
                            Divider(color: theme.dividerColor, height: 1),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                'Position / Role',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  position,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: theme.dividerColor, height: 1),
                    const SizedBox(height: 20),

                    // Dedicated "Center" Section
                    Text(
                      'Center',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (localCenter.isNotEmpty) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                'Local Center',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  localCenter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                            if (district.isNotEmpty ||
                                area.isNotEmpty ||
                                centerAddress.isNotEmpty)
                              Divider(color: theme.dividerColor, height: 1),
                          ],
                          if (district.isNotEmpty || area.isNotEmpty) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                'District & Area',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  [
                                    if (district.isNotEmpty) district,
                                    if (area.isNotEmpty) area,
                                  ].join(' • '),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                            if (centerAddress.isNotEmpty)
                              Divider(color: theme.dividerColor, height: 1),
                          ],
                          if (centerAddress.isNotEmpty)
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                'Worships at',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  centerAddress,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          if (localCenter.isEmpty &&
                              district.isEmpty &&
                              area.isEmpty &&
                              centerAddress.isEmpty)
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              title: Text(
                                'No center information shared yet.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: theme.dividerColor, height: 1),
                    const SizedBox(height: 20),

                    // Post Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Post',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userPosts.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_userPosts.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // Edge-to-Edge Post Cards Feed (Matching Home Page)
            if (!isLocked) ...[
              if (_isLoadingPosts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_userPosts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        AppIcon(
                          icon: HugeIcons.strokeRoundedNews,
                          size: 48,
                          color: theme.hintColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No posts yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
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
                  itemCount: _userPosts.length,
                  itemBuilder: (context, index) {
                    final post = _userPosts[index];
                    return CommunityPostCard(
                      post: post,
                      onPostUpdated: _fetchUserPosts,
                      onPostDeleted: () {
                        setState(() {
                          _userPosts.removeWhere((p) => p.id == post.id);
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
