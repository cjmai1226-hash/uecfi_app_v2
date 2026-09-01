import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/contributor_badge.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool showAppBar;

  const LeaderboardScreen({super.key, this.showAppBar = true});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<QuerySnapshot> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _fetchLeaderboard();
  }

  Future<QuerySnapshot> _fetchLeaderboard() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('contributions', isGreaterThan: 0)
        .orderBy('contributions', descending: true)
        .get();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _leaderboardFuture = _fetchLeaderboard();
    });
    await _leaderboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Community Leaderboard'), elevation: 0)
          : null,
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<UserProfile>(
          valueListenable: UserService.instance,
          builder: (context, currentUser, _) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: FutureBuilder<QuerySnapshot>(
                future: _leaderboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Error loading leaderboard',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _handleRefresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Calculate current user standing
                  int currentUserRank = -1;
                  int currentUserContributions = currentUser.contributions;
                  for (int i = 0; i < docs.length; i++) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    if (data['email']?.toString().toLowerCase() ==
                        currentUser.email.toLowerCase()) {
                      currentUserRank = i + 1;
                      currentUserContributions =
                          data['contributions'] as int? ?? 0;
                      break;
                    }
                  }

                  final top3Docs = docs.take(3).toList();
                  final restDocs = docs.length > 3
                      ? docs.sublist(3)
                      : <QueryDocumentSnapshot>[];
                  final displayedRestCount = restDocs.length > 97
                      ? 97
                      : restDocs.length;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Banner with Accenture Tech Gradient
                        _buildHeroBanner(context, theme),

                        // Visual Top 3 Championship Podium
                        if (docs.isNotEmpty)
                          _buildPodiumSection(
                            context,
                            theme,
                            top3Docs,
                            currentUser,
                          ),

                        // Current User Standing & Next Tier Progress Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: _buildUserProgressCard(
                            context,
                            theme,
                            currentUser,
                            currentUserRank,
                            currentUserContributions,
                          ),
                        ),

                        // Section Title for Remaining Ranks
                        if (restDocs.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Rankings',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Top 100 Contributors',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedRestCount,
                                separatorBuilder: (context, idx) => Divider(
                                  color: theme.dividerColor,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final data =
                                      restDocs[index].data()
                                          as Map<String, dynamic>;
                                  final String name = data['name'] ?? 'Member';
                                  final String localCenter =
                                      data['centerName'] ?? '';
                                  final int contributions =
                                      data['contributions'] as int? ?? 0;
                                  final String email = data['email'] ?? '';
                                  final bool isSelf =
                                      email.toLowerCase() ==
                                      currentUser.email.toLowerCase();
                                  final int rank = index + 4;

                                  return ListTile(
                                    tileColor: isSelf
                                        ? theme.colorScheme.primary.withValues(
                                            alpha: isDark ? 0.15 : 0.08,
                                          )
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        index == 0
                                            ? 16
                                            : (index == displayedRestCount - 1
                                                  ? 16
                                                  : 0),
                                      ),
                                    ),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelf
                                            ? theme.colorScheme.primary
                                            : theme.dividerColor.withValues(
                                                alpha: 0.4,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#$rank',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelf
                                                ? Colors.white
                                                : theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isSelf
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (name.toLowerCase() ==
                                            'devchristian') ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.verified_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 14,
                                          ),
                                        ],
                                        const SizedBox(width: 6),
                                        getContributorBadge(
                                          contributions,
                                          theme,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                    subtitle: localCenter.isNotEmpty
                                        ? Text(
                                            localCenter,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$contributions pts',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ] else if (docs.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 48,
                              horizontal: 24,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 56,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ranked contributors yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Be the first to contribute by posting or submitting hymns!',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ] else ...[
                          const SizedBox(height: 80),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    final endOfSeason = DateTime(now.year, 12, 31, 23, 59, 59);
    final daysRemaining = endOfSeason.difference(now).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF460073), Color(0xFFA100FF), Color(0xFF6B00B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: Colors.amber,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Season ${now.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$daysRemaining days left in season',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showMechanicsBottomSheet(context, theme),
            tooltip: 'Leaderboard Rules & Info',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSection(
    BuildContext context,
    ThemeData theme,
    List<QueryDocumentSnapshot> top3,
    UserProfile currentUser,
  ) {
    final first = top3.isNotEmpty
        ? top3[0].data() as Map<String, dynamic>
        : null;
    final second = top3.length > 1
        ? top3[1].data() as Map<String, dynamic>
        : null;
    final third = top3.length > 2
        ? top3[2].data() as Map<String, dynamic>
        : null;

    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (first != null)
            _buildTopRankCard(
              context: context,
              theme: theme,
              data: first,
              rank: 1,
              currentUser: currentUser,
              isDark: isDark,
            ),
          if (second != null) ...[
            const SizedBox(height: 8),
            _buildTopRankCard(
              context: context,
              theme: theme,
              data: second,
              rank: 2,
              currentUser: currentUser,
              isDark: isDark,
            ),
          ],
          if (third != null) ...[
            const SizedBox(height: 8),
            _buildTopRankCard(
              context: context,
              theme: theme,
              data: third,
              rank: 3,
              currentUser: currentUser,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopRankCard({
    required BuildContext context,
    required ThemeData theme,
    required Map<String, dynamic> data,
    required int rank,
    required UserProfile currentUser,
    required bool isDark,
  }) {
    final name = data['name'] ?? 'Member';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    final contributions = data['contributions'] as int? ?? 0;
    final String localCenter = data['centerName'] ?? '';
    final isDevChristian = name.toLowerCase() == 'devchristian';
    final bool isSelf =
        data['email']?.toString().toLowerCase() ==
        currentUser.email.toLowerCase();

    final Color accentColor;
    final List<Color> gradientColors;
    final List<Color> pillGradient;
    final String tagLabel;
    final IconData tagIcon;

    if (rank == 1) {
      accentColor = const Color(0xFFFFD700);
      gradientColors = const [
        Color(0xFFF2994A),
        Color(0xFFF2C94C),
        Color(0xFFFFD700),
      ];
      pillGradient = const [Color(0xFFFFD700), Color(0xFFFFA000)];
      tagLabel = 'SEASON CHAMPION';
      tagIcon = Icons.workspace_premium_rounded;
    } else if (rank == 2) {
      accentColor = const Color(0xFFC0C0C0);
      gradientColors = const [Color(0xFF8E9EAB), Color(0xFFEFEFBB)];
      pillGradient = const [Color(0xFF90A4AE), Color(0xFF607D8B)];
      tagLabel = 'RUNNER UP';
      tagIcon = Icons.military_tech_rounded;
    } else {
      accentColor = const Color(0xFFCD7F32);
      gradientColors = const [Color(0xFF9E653A), Color(0xFFE8A87C)];
      pillGradient = const [Color(0xFFD38312), Color(0xFF804A00)];
      tagLabel = '3RD PLACE';
      tagIcon = Icons.stars_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(
            alpha: isDark ? (rank == 1 ? 0.6 : 0.4) : (rank == 1 ? 0.7 : 0.5),
          ),
          width: rank == 1 ? 1.5 : 1.2,
        ),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar + Rank Badge (and Crown for #1)
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: rank == 1 ? 0.35 : 0.2,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: rank == 1 ? 24 : 22,
                  backgroundColor: theme.cardColor,
                  child: isDevChristian
                      ? Padding(
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/brand_mark.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : (isSelf && currentUser.avatarPath.isNotEmpty
                            ? ClipOval(
                                child: Image.file(
                                  File(currentUser.avatarPath),
                                  fit: BoxFit.cover,
                                  width: rank == 1 ? 48 : 44,
                                  height: rank == 1 ? 48 : 44,
                                ),
                              )
                            : Text(
                                initial,
                                style: TextStyle(
                                  fontSize: rank == 1 ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              )),
                ),
              ),

              // Crown on top for #1
              if (rank == 1)
                const Positioned(
                  top: -12,
                  child: Text('👑', style: TextStyle(fontSize: 16)),
                ),

              // Rank Badge pill
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.5,
                    vertical: 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // User Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tagIcon, size: 10.5, color: accentColor),
                      const SizedBox(width: 3),
                      Text(
                        tagLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isSelf ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                    if (isDevChristian) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        color: theme.colorScheme.primary,
                        size: 14,
                      ),
                    ],
                    const SizedBox(width: 4),
                    getContributorBadge(contributions, theme, size: 14),
                  ],
                ),
                if (localCenter.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    localCenter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Points Highlight Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pillGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$contributions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: rank == 1 ? Colors.black87 : Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'PTS',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: rank == 1 ? Colors.black54 : Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProgressCard(
    BuildContext context,
    ThemeData theme,
    UserProfile currentUser,
    int userRank,
    int points,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    // Calculate current tier and next target
    String currentTierName;
    String nextTierName;
    int nextTierTarget;
    double progress;

    if (points >= 100) {
      currentTierName = 'Pillar of the Community';
      nextTierName = 'Max Tier Reached';
      nextTierTarget = 100;
      progress = 1.0;
    } else if (points >= 50) {
      currentTierName = 'Top Contributor';
      nextTierName = 'Pillar (100 pts)';
      nextTierTarget = 100;
      progress = (points - 50) / (100 - 50);
    } else if (points >= 10) {
      currentTierName = 'Active Contributor';
      nextTierName = 'Top (50 pts)';
      nextTierTarget = 50;
      progress = (points - 10) / (50 - 10);
    } else {
      currentTierName = 'Member';
      nextTierName = 'Active (10 pts)';
      nextTierTarget = 10;
      progress = points / 10.0;
    }
    progress = progress.clamp(0.0, 1.0);

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage:
                      currentUser.avatarPath.isNotEmpty &&
                          currentUser.nickname.toLowerCase() != 'devchristian'
                      ? FileImage(File(currentUser.avatarPath))
                      : null,
                  child: currentUser.nickname.toLowerCase() == 'devchristian'
                      ? Padding(
                          padding: const EdgeInsets.all(2.5),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/brand_mark.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : (currentUser.avatarPath.isEmpty
                            ? Text(
                                currentUser.nickname.isNotEmpty
                                    ? currentUser.nickname[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentUser.nickname.isNotEmpty
                                  ? currentUser.nickname
                                  : 'Your Standing',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          getContributorBadge(points, theme, size: 14),
                        ],
                      ),
                      Text(
                        currentTierName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        userRank > 0 ? '#$userRank' : 'Unranked',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$points pts',
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
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Tier: $nextTierName',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                  ),
                ),
                Text(
                  points >= 100
                      ? '100% Completed'
                      : '$points / $nextTierTarget pts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark
                    ? const Color(0xFF333333)
                    : const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchFacebookPage(BuildContext context) async {
    final url = Uri.parse(
      'https://www.facebook.com/profile.php?id=61582048631893',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open Facebook: $e')));
      }
    }
  }

  void _showMechanicsBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leaderboard Mechanics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Earn points and level up your contributor status by helping grow and maintain the UECFI member community app!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Point breakdown
                Text(
                  'How to Earn Points',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMechanicRow(
                  icon: Icons.post_add_rounded,
                  title: 'Publish a Feed Post',
                  subtitle: '+1 point per published post',
                  theme: theme,
                ),
                _buildMechanicRow(
                  icon: Icons.music_note_rounded,
                  title: 'Suggest Song Lyrics',
                  subtitle: '+1 point per song suggested',
                  theme: theme,
                ),
                _buildMechanicRow(
                  icon: Icons.edit_location_alt_rounded,
                  title: 'Suggest Center Details',
                  subtitle: '+1 point per update suggestion',
                  theme: theme,
                ),
                const SizedBox(height: 24),

                // Medal breakdown
                Text(
                  'Contributor Medal Tiers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMedalRow(
                  icon: Icons.workspace_premium_rounded,
                  color: Colors.blueGrey[400]!,
                  title: 'Active Contributor',
                  requirement: '10+ contribution points',
                  theme: theme,
                ),
                _buildMedalRow(
                  icon: Icons.stars_rounded,
                  color: Colors.orange[600]!,
                  title: 'Top Contributor',
                  requirement: '50+ contribution points',
                  theme: theme,
                ),
                _buildMedalRow(
                  icon: Icons.military_tech_rounded,
                  color: Colors.amber[700]!,
                  title: 'Pillar of the Community',
                  requirement: '100+ contribution points',
                  theme: theme,
                ),
                const SizedBox(height: 24),

                // Rewards breakdown
                Text(
                  'Rewards & Recognition',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Special rewards and recognition may be awarded to the local Worship Centers of the top contributors of the season! This is a wonderful way to support and give back to your home church center. Check our official Facebook page for announcements, prize details, and guidelines.\n\nNote: Spamming, posting duplicate content, or abusing submissions will result in immediate disqualification and removal of your ranked status.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _launchFacebookPage(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1877F2).withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1877F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.facebook,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Follow us on Facebook',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1877F2),
                                ),
                              ),
                              Text(
                                'Tap to visit official page',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF1877F2),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Disclaimer: Google is not a sponsor of or involved in this community recognition program.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMechanicRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalRow({
    required IconData icon,
    required Color color,
    required String title,
    required String requirement,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  requirement,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
