import 'package:flutter/material.dart';
import '../../widgets/uecfi_logo.dart';
import '../../widgets/sparkling_trophy_icon.dart';
import 'home_screen.dart';
import '../features/prayers_screen.dart';
import '../features/songs_screen.dart';
import '../features/centers_screen.dart';
import '../features/leaderboard_screen.dart';
import '../features/menu_screen.dart';
import '../features/search_screen.dart';
import '../../services/ad_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Widget> _screens = const [
    HomeScreen(),
    PrayersScreen(),
    SongsScreen(),
    CentersScreen(),
    LeaderboardScreen(showAppBar: false),
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const UecfiLogo(
          fontSize: 18,
        ),
        centerTitle: false,
        actions: [
          // Search Icon Button routing to Isolated Search Screen
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

          // Menu Icon Button routing to Menu Screen Page
          IconButton(
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
          const SizedBox(width: 8),
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
            Tab(
              icon: SparklingTrophyIcon(
                isSelected: _tabController.index == 4,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: _screens,
        ),
      ),
    );
  }
}
