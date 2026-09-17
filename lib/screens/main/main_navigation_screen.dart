import 'dart:io';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../features/prayers_screen.dart';
import '../features/songs_screen.dart';
import '../features/centers_screen.dart';
import '../features/profile_screen.dart';
import '../features/menu_screen.dart';
import '../features/search_screen.dart';
import '../../services/ad_service.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/user_avatar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Widget> _screens = const [
    HomeScreen(),
    PrayersScreen(),
    SongsScreen(),
    CentersScreen(),
    ProfileScreen(showAppBar: false),
  ];

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      // Rebuild to update selected tab icon states (filled vs outlined)
      if (!_tabController.indexIsChanging) {
        if (_currentTabIndex != _tabController.index) {
          _currentTabIndex = _tabController.index;
          AdService().showInterstitialIfReady();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildProfileTabIcon(
    BuildContext context,
    UserProfile profile, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final hasPhoto = (profile.avatarPath.isNotEmpty &&
            File(profile.avatarPath).existsSync()) ||
        (profile.avatarUrl.trim().isNotEmpty &&
            profile.avatarUrl.startsWith('http'));
    final hasProfile =
        profile.nickname.trim().isNotEmpty || profile.email.trim().isNotEmpty;

    if (hasPhoto || hasProfile) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (theme.brightness == Brightness.dark
                    ? Colors.white30
                    : Colors.black26),
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        padding: const EdgeInsets.all(1),
        child: ClipOval(
          child: UserAvatar(
            authorName: profile.nickname.isNotEmpty
                ? profile.nickname
                : (profile.firstName.isNotEmpty ? profile.firstName : 'M'),
            localAvatarPath: profile.avatarPath,
            avatarUrl: profile.avatarUrl,
            radius: 12,
            borderRadius: BorderRadius.circular(12),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Icon(
      isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
      size: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MenuScreen(showAppBar: true),
              ),
            );
          },
        ),
        title: const Text(
          'uecfi app',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          // Search Icon Button routing to Isolated Search Screen with Contextual Initial Category
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () {
              SearchCategory initialCategory = SearchCategory.all;
              if (_tabController.index == 1) {
                initialCategory = SearchCategory.prayers;
              } else if (_tabController.index == 2) {
                initialCategory = SearchCategory.songs;
              } else if (_tabController.index == 3) {
                initialCategory = SearchCategory.centers;
              }

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SearchScreen(initialCategory: initialCategory),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(
                _tabController.index == 0
                    ? Icons.home_rounded
                    : Icons.home_outlined,
              ),
            ),
            Tab(
              icon: Icon(
                _tabController.index == 1
                    ? Icons.volunteer_activism_rounded
                    : Icons.volunteer_activism_outlined,
              ),
            ),
            Tab(
              icon: Icon(
                _tabController.index == 2
                    ? Icons.music_note_rounded
                    : Icons.music_note_outlined,
              ),
            ),
            Tab(
              icon: Icon(
                _tabController.index == 3
                    ? Icons.place_rounded
                    : Icons.place_outlined,
              ),
            ),
            ValueListenableBuilder<UserProfile>(
              valueListenable: UserService.instance,
              builder: (context, profile, _) {
                return Tab(
                  icon: _buildProfileTabIcon(
                    context,
                    profile,
                    isSelected: _tabController.index == 4,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(controller: _tabController, children: _screens),
      ),
    );
  }
}

