import 'package:flutter/material.dart';
import '../../models/center_model.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../widgets/user_avatar.dart';
import '../features/profile_screen.dart';
import '../features/public_profile_screen.dart';

class CenterPeopleScreen extends StatefulWidget {
  final CenterModel center;
  final int initialTabIndex;

  const CenterPeopleScreen({
    super.key,
    required this.center,
    this.initialTabIndex = 0,
  });

  @override
  State<CenterPeopleScreen> createState() => _CenterPeopleScreenState();
}

class _CenterPeopleScreenState extends State<CenterPeopleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _fetchMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    final members = await FirestoreService().getCenterMembers(
      widget.center.name,
      widget.center.address,
    );
    if (mounted) {
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    }
  }

  String _capitalize(String text) {
    if (text.trim().isEmpty) return '';
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  void _openMemberProfile(
    BuildContext context, {
    required String email,
    required String nickname,
    String? avatarUrl,
    String? avatarPath,
    String? localCenter,
  }) {
    final currentUser = UserService.instance.value;
    final isSelf = (email.isNotEmpty &&
            email.toLowerCase() == currentUser.email.toLowerCase()) ||
        (nickname.isNotEmpty &&
            nickname.toLowerCase() == currentUser.nickname.toLowerCase());

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
            userEmail: email,
            initialNickname: nickname,
            initialAvatarUrl: avatarUrl,
            initialLocalCenter: localCenter ?? widget.center.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().streamCenterVisitors(widget.center.name),
      builder: (context, visitorSnapshot) {
        final List<Map<String, dynamic>> allVisitors =
            visitorSnapshot.data ?? [];

        final filteredMembers = _members.where((member) {
          if (_searchQuery.isEmpty) return true;
          final name = (member['name'] as String? ?? '').toLowerCase();
          final position = (member['position'] as String? ?? '').toLowerCase();
          return name.contains(_searchQuery) || position.contains(_searchQuery);
        }).toList();

        final filteredVisitors = allVisitors.where((visitor) {
          if (_searchQuery.isEmpty) return true;
          final name = (visitor['nickname'] as String? ?? '').toLowerCase();
          final home = (visitor['homeCenter'] as String? ?? '').toLowerCase();
          final position = (visitor['position'] as String? ?? '').toLowerCase();
          return name.contains(_searchQuery) ||
              home.contains(_searchQuery) ||
              position.contains(_searchQuery);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  widget.center.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.center.address.isNotEmpty)
                  Text(
                    widget.center.address,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.textTheme.bodySmall?.color,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 18),
                          const SizedBox(width: 6),
                          const Text('Members'),
                          if (_members.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white12
                                        : const Color(0xFFE4E4EC)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_members.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _tabController.index == 0
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.place_rounded, size: 18),
                          const SizedBox(width: 6),
                          const Text('Visitors'),
                          if (allVisitors.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white12
                                        : const Color(0xFFE4E4EC)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${allVisitors.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _tabController.index == 1
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? 'Search members by name or role...'
                        : 'Search visitors by name or home center...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1F1F2B)
                        : const Color(0xFFEFEFF5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Members List
                    _isLoadingMembers
                        ? const Center(child: CircularProgressIndicator())
                        : filteredMembers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 48,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No members match "$_searchQuery"'
                                            : 'No registered members for this center yet.',
                                        style: TextStyle(
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: filteredMembers.length,
                                separatorBuilder: (context, index) =>
                                    Divider(color: theme.dividerColor, height: 1),
                                itemBuilder: (context, index) {
                                  final member = filteredMembers[index];
                                  final String nickname =
                                      member['name'] ?? '';
                                  final String rawPosition =
                                      member['position'] ?? '';
                                  final String positionVal =
                                      rawPosition.trim().isEmpty
                                          ? 'Member'
                                          : rawPosition.trim();
                                  final String position =
                                      _capitalize(positionVal);
                                  final String displayName =
                                      nickname.isNotEmpty
                                          ? _capitalize(nickname)
                                          : 'Member';
                                  final bool isDevChristian =
                                      nickname.toLowerCase() == 'devchristian';

                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    leading: UserAvatar(
                                      authorName: displayName,
                                      avatarUrl:
                                          member['avatarUrl'] as String?,
                                      radius: 20,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        if (isDevChristian) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.verified_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 15,
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      position,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                    ),
                                    onTap: () => _openMemberProfile(
                                      context,
                                      email: member['email'] ?? '',
                                      nickname: nickname,
                                      avatarUrl:
                                          member['avatarUrl'] as String?,
                                      localCenter: widget.center.name,
                                    ),
                                  );
                                },
                              ),

                    // Tab 2: Visitors List
                    filteredVisitors.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 48,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No visitors match "$_searchQuery"'
                                        : 'No brethren have visited this center yet.',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredVisitors.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: theme.dividerColor, height: 1),
                            itemBuilder: (context, index) {
                              final visitor = filteredVisitors[index];
                              final nickname =
                                  visitor['nickname'] ?? 'Member';
                              final homeCenter =
                                  visitor['homeCenter'] as String? ?? '';
                              final position =
                                  visitor['position'] as String? ?? '';

                              String subtext = '';
                              if (homeCenter.isNotEmpty) {
                                subtext = 'From $homeCenter';
                              } else if (position.isNotEmpty) {
                                subtext = position;
                              } else {
                                subtext = 'Visiting Member';
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                leading: UserAvatar(
                                  authorName: nickname,
                                  avatarUrl: visitor['avatarUrl'] as String?,
                                  localAvatarPath:
                                      visitor['avatarPath'] as String?,
                                  radius: 20,
                                ),
                                title: Text(
                                  nickname,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                subtitle: Text(
                                  subtext,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                ),
                                onTap: () => _openMemberProfile(
                                  context,
                                  email: visitor['userEmail'] ?? '',
                                  nickname: nickname,
                                  avatarUrl: visitor['avatarUrl'] as String?,
                                  avatarPath:
                                      visitor['avatarPath'] as String?,
                                  localCenter: homeCenter,
                                ),
                              );
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
  }
}
