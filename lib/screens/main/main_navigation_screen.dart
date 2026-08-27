import 'package:flutter/material.dart';
import '../../widgets/uecfi_logo.dart';
import '../../widgets/app_drawer.dart';
import '../features/submit_song_screen.dart';
import '../features/create_post_screen.dart';
import 'home_screen.dart';
import '../features/prayers_screen.dart';
import '../features/songs_screen.dart';
import '../features/centers_screen.dart';
import '../features/profile_screen.dart';
import '../features/search_screen.dart';

import 'dart:io';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';

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
    ProfileScreen(showAppBar: false),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      // Rebuild to update selected tab icon states (filled vs outlined)
      if (!_tabController.indexIsChanging) {
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const UecfiLogo(
          fontSize: 18,
        ),
        centerTitle: false,
        actions: [
          // Add button with PopupMenu for Post and Submit
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add options',
            onSelected: (value) {
              if (value == 'post') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              } else if (value == 'submit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubmitSongScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'post',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Post'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'submit',
                child: Row(
                  children: [
                    Icon(Icons.queue_music_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Submit'),
                  ],
                ),
              ),
            ],
          ),

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
              icon: ValueListenableBuilder<UserProfile>(
                valueListenable: UserService.instance,
                builder: (context, profile, child) {
                  final isSelected = _tabController.index == 4;
                  final nickname = profile.nickname.toLowerCase();
                  final isDevChristian = nickname == 'devchristian';
                  if (profile.avatarPath.isNotEmpty || isDevChristian) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundImage: !isDevChristian && profile.avatarPath.isNotEmpty
                              ? FileImage(File(profile.avatarPath))
                              : null,
                          child: isDevChristian
                              ? Padding(
                                  padding: const EdgeInsets.all(1.5),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/brand_mark.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }
                  return Icon(
                    isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
    );
  }
}
