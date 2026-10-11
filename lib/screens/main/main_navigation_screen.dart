import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import 'home_screen.dart';
import '../features/prayers_screen.dart';
import '../features/songs_screen.dart';
import '../features/centers_screen.dart';
import '../features/rewards_screen.dart';
import '../features/menu_screen.dart';
import '../features/search_screen.dart';
import '../forms/create_post_screen.dart';
import '../forms/submit_song_screen.dart';
import '../forms/suggest_new_center_screen.dart';
import '../../services/ad_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    PrayersScreen(),
    SongsScreen(),
    CentersScreen(),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor = theme.hintColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: AppIcon(
            icon: HugeIcons.strokeRoundedMenu01,
            size: 22,
            color: theme.appBarTheme.iconTheme?.color ?? theme.iconTheme.color,
          ),
          tooltip: 'Menu',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MenuScreen(showAppBar: true),
              ),
            );
          },
        ),
        titleSpacing: 4,
        title: Text(
          'uecfi app',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.w800,
            fontSize: 21,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          // Plus / Create Menu Button
          PopupMenuButton<String>(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedSquarePlus,
              size: 22,
              color:
                  theme.appBarTheme.iconTheme?.color ?? theme.iconTheme.color,
            ),
            tooltip: 'Create or Submit',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'post') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              } else if (value == 'song') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubmitSongScreen(),
                  ),
                );
              } else if (value == 'center') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SuggestNewCenterScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'post',
                child: Row(
                  children: [
                    AppIcon(
                      icon: HugeIcons.strokeRoundedEdit02,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'song',
                child: Row(
                  children: [
                    AppIcon(
                      icon: HugeIcons.strokeRoundedMusic02,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Submit Song',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'center',
                child: Row(
                  children: [
                    AppIcon(
                      icon: HugeIcons.strokeRoundedLocationAdd01,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Suggest New Center',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Search Icon Button routing to Isolated Search Screen with Contextual Initial Category
          IconButton(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 22,
              color:
                  theme.appBarTheme.iconTheme?.color ?? theme.iconTheme.color,
            ),
            tooltip: 'Search',
            onPressed: () {
              SearchCategory initialCategory = SearchCategory.all;
              if (_selectedIndex == 1) {
                initialCategory = SearchCategory.prayers;
              } else if (_selectedIndex == 2) {
                initialCategory = SearchCategory.songs;
              } else if (_selectedIndex == 3) {
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

          // Rewards Store Icon Button (placed at the end)
          IconButton(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedStore02,
              size: 22,
              color:
                  theme.appBarTheme.iconTheme?.color ?? theme.iconTheme.color,
            ),
            tooltip: 'Dev Coins & Rewards',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RewardsScreen(showAppBar: true),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
            AdService().showInterstitialIfReady();
          }
        },
        destinations: [
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedHome01,
              size: 24,
              color: unselectedColor,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedHome01,
              size: 24,
              color: primaryColor,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedHandPrayer,
              size: 24,
              color: unselectedColor,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedHandPrayer,
              size: 24,
              color: primaryColor,
            ),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedMusic02,
              size: 24,
              color: unselectedColor,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedMusic02,
              size: 24,
              color: primaryColor,
            ),
            label: 'Songs',
          ),
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedMapsGlobal01,
              size: 24,
              color: unselectedColor,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedMapsGlobal01,
              size: 24,
              color: primaryColor,
            ),
            label: 'Centers',
          ),
        ],
      ),
    );
  }
}
