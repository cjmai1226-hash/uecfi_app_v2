import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/contributor_badge.dart';
import '../../widgets/community_post_card.dart';
import '../../models/blog_post.dart';
import '../../services/user_service.dart';
import '../../services/firestore_service.dart';
import '../../services/database_helper.dart';
import '../../models/center_model.dart';
import '../details/center_detail_screen.dart';
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
          final items = await FirestoreService().getUserContributions(cleanEmail);
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
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
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
                      Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                      SizedBox(height: 8),
                      Text('Unable to load photo', style: TextStyle(color: Colors.white70)),
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

  Future<void> _openCenterDetail(
    BuildContext context,
    String centerName,
    String centerAddress,
  ) async {
    try {
      final allCenters = await DatabaseHelper.getAllCenters();
      final match = allCenters.firstWhere(
        (c) => c.name.trim().toLowerCase() == centerName.trim().toLowerCase(),
        orElse: () => CenterModel(
          name: centerName,
          address: centerAddress,
          district: '',
          area: '',
          location: '',
          contact: '',
          status: 'Active',
          history: '',
          page: '',
        ),
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CenterDetailScreen(center: match),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening center detail: $e');
    }
  }

  String _extractShortAddress(String rawAddress) {
    final clean = rawAddress.trim();
    if (clean.isEmpty) return 'Center';
    final parts = clean.split(',');
    if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
      return parts.first.trim();
    }
    return clean;
  }

  void _showAllVisitedCentersSheet(
    BuildContext context, {
    required List<Map<String, dynamic>> visits,
    required String memberName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Column(
                children: [
                  // Top Drag Handle Pill
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Visited Centers',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${visits.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 1),

                  // List of Centers
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: visits.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final visit = visits[index];
                        final centerName =
                            (visit['centerName'] as String?)?.trim() ??
                                'Worship Center';
                        final centerAddress =
                            (visit['centerAddress'] as String?)?.trim() ?? '';
                        final dynamic timestamp = visit['visitedAt'];
                        String dateStr = '';
                        if (timestamp is Timestamp) {
                          final dt = timestamp.toDate();
                          final months = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ];
                          dateStr =
                              'Visited on ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
                        }

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.place_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              centerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: (centerAddress.isNotEmpty ||
                                    dateStr.isNotEmpty)
                                ? Text(
                                    [
                                      if (centerAddress.isNotEmpty)
                                        centerAddress,
                                      if (dateStr.isNotEmpty) dateStr,
                                    ].join(' • '),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _openCenterDetail(
                                context,
                                centerName,
                                centerAddress,
                              );
                            },
                          ),
                        );
                      },
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
    final int contributions = _userData?['contributions'] as int? ?? 0;
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
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
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
                                theme.colorScheme.primary.withValues(alpha: 0.8),
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
                          Icon(
                            Icons.verified_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ],
                        const SizedBox(width: 6),
                        getContributorBadge(contributions, theme, size: 20),
                      ],
                    ),
                  ),

                  // Centered contributions breakdown subtitle
                  Builder(
                    builder: (context) {
                      final int postCount = _contributions
                          .where((item) =>
                              (item['type'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('post') &&
                              item['status'] != 'reported')
                          .length;
                      final int songCount = _contributions
                          .where((item) =>
                              (item['type'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('song') &&
                              item['status'] != 'reported')
                          .length;
                      final int centerCount = _contributions
                          .where((item) =>
                              (item['type'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('center') &&
                              item['status'] != 'reported')
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
                        icon: const Icon(Icons.edit_outlined, size: 18),
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
                              child: const Icon(
                                Icons.shield_rounded,
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
                      'PERSONAL DETAILS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    if (position.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          position,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Position / Role',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Divider(color: theme.dividerColor, height: 1),
                    const SizedBox(height: 20),

                    // Dedicated "Center" Section
                    Text(
                      'CENTER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (localCenter.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          localCenter,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Local Center',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    if (district.isNotEmpty || area.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          [
                            if (district.isNotEmpty) district,
                            if (area.isNotEmpty) area,
                          ].join(' • '),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'District & Area',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    if (centerAddress.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          centerAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Worships at',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Visited Centers Subsection
                    Builder(
                      builder: (context) {
                        final targetEmail = widget.userEmail.isNotEmpty
                            ? widget.userEmail
                            : (_userData?['email'] as String? ?? '');
                        return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: FirestoreService()
                              .streamUserVisitedCenters(targetEmail),
                          builder: (context, snapshot) {
                            final visits = snapshot.data ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'VISITED CENTERS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.5,
                                              letterSpacing: 0.8,
                                              color: theme
                                                  .textTheme.bodySmall?.color,
                                            ),
                                          ),
                                          if (visits.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${visits.length}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (visits.length > 3)
                                        InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () =>
                                              _showAllVisitedCentersSheet(
                                            context,
                                            visits: visits,
                                            memberName: displayName,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              'View All',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (visits.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'No visited centers recorded yet.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontStyle: FontStyle.italic,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int i = 0; i < 4; i++)
                                        if (i < visits.length)
                                          Expanded(
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                final visit = visits[i];
                                                _openCenterDetail(
                                                  context,
                                                  (visit['centerName']
                                                              as String?)
                                                          ?.trim() ??
                                                      'Center',
                                                  (visit['centerAddress']
                                                              as String?)
                                                          ?.trim() ??
                                                      '',
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 6,
                                                  horizontal: 2,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 24,
                                                      backgroundColor: isDark
                                                          ? const Color(
                                                              0xFF3A3B3C)
                                                          : const Color(
                                                              0xFFE4E6EB),
                                                      child: Icon(
                                                        Icons.church_rounded,
                                                        size: 22,
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      (visits[i]['centerName']
                                                                  as String?)
                                                              ?.trim() ??
                                                          'Center',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: theme
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _extractShortAddress(
                                                        (visits[i]['centerAddress']
                                                                as String?) ??
                                                            '',
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                    ],
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
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
                        Icon(
                          Icons.article_outlined,
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
