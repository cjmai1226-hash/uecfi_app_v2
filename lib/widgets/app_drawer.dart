import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../screens/features/settings_screen.dart';
import '../screens/features/bylaws_screen.dart';
import '../screens/features/profile_screen.dart';
import '../screens/features/submit_song_screen.dart';
import '../screens/features/bible_screen.dart';
import '../screens/features/help_feedback_screen.dart';
import '../screens/admin/admin_tickets_screen.dart';
import '../screens/admin/admin_songs_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _launchFacebookPage(BuildContext context) async {
    final url = Uri.parse('https://www.facebook.com/profile.php?id=61582048631893');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Facebook: $e')),
        );
      }
    }
  }

  void _showFeatureDialog(BuildContext context, String title, String message) {
    Navigator.of(context).pop(); // Close drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Profile Card
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              child: ValueListenableBuilder<UserProfile>(
                valueListenable: UserService.instance,
                builder: (context, profile, child) {
                  final nickname = profile.nickname.isNotEmpty
                      ? profile.nickname
                      : 'Member';
                  final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'M';
                  final hasAvatar = profile.avatarPath.isNotEmpty;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF242526)
                        : const Color(0xFFF0F2F5),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(showAppBar: true),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Profile picture or fallback avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primary,
                              backgroundImage: nickname.toLowerCase() != 'devchristian' && hasAvatar
                                  ? FileImage(File(profile.avatarPath))
                                  : null,
                              child: nickname.toLowerCase() == 'devchristian'
                                  ? Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/brand_mark.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  : (!hasAvatar
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null),
                            ),
                            const SizedBox(width: 12),
                            // User Name & View Profile prompt
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nickname,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'View Profile',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Scrollable Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // Section: Church Resources
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                    child: Text(
                      'Resources',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      Icons.menu_book_rounded,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    title: const Text('Ilocano Bible'),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BibleScreen(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      Icons.description_outlined,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    title: const Text('Church Bylaws'),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BylawsScreen(),
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: theme.dividerColor, height: 16),
                  ),

                  // Section: Tools and Content
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                    child: Text(
                      'Tools and Content',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      Icons.music_note_rounded,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    title: const Text('Submit Song'),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubmitSongScreen(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      Icons.star_outline_rounded,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    title: const Text('Rate this app'),
                    onTap: () => _showFeatureDialog(
                      context,
                      'Rate UECFI APP',
                      'Thank you for using UECFI APP Premium! Opening store review page...',
                    ),
                  ),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      Icons.help_outline_rounded,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    title: const Text('Help and Feedback'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpFeedbackScreen(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(
                      Icons.settings_outlined,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  ValueListenableBuilder<UserProfile>(
                    valueListenable: UserService.instance,
                    builder: (context, profile, child) {
                      if (profile.memberId != 'USER1') {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: theme.dividerColor, height: 16),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 6),
                            child: Text(
                              'Admin Panel',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                            title: const Text('Helpline Tickets'),
                            onTap: () {
                              Navigator.of(context).pop(); // Close drawer
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AdminTicketsScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(
                              Icons.music_video_rounded,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                            title: const Text('Song Submissions'),
                            onTap: () {
                              Navigator.of(context).pop(); // Close drawer
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AdminSongsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Pressable Facebook Card Fixed at Drawer Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  _launchFacebookPage(context);
                },
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
            ),
          ],
        ),
      ),
    );
  }
}
