import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import 'settings_screen.dart';
import 'bylaws_screen.dart';
import 'profile_screen.dart';
import '../../services/chords_settings_service.dart';
import '../../services/ad_service.dart';
import 'bible_screen.dart';
import 'help_feedback_screen.dart';
import '../admin/admin_tickets_screen.dart';
import '../admin/admin_songs_screen.dart';
import '../admin/admin_center_updates_screen.dart';
import '../../widgets/user_avatar.dart';

class MenuScreen extends StatelessWidget {
  final bool showAppBar;

  const MenuScreen({
    super.key,
    this.showAppBar = false,
  });

  Future<void> _launchFacebookPage(BuildContext context) async {
    final url =
        Uri.parse('https://www.facebook.com/profile.php?id=61582048631893');
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 22,
        color: theme.brightness == Brightness.dark
            ? Colors.white70
            : Colors.black87,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.hintColor,
            size: 20,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Menu'),
              elevation: 0,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card at Top
            ValueListenableBuilder<UserProfile>(
              valueListenable: UserService.instance,
              builder: (context, profile, child) {
                final nickname = profile.nickname.isNotEmpty
                    ? profile.nickname
                    : 'Member';
                return Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProfileScreen(showAppBar: true),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          UserAvatar(
                            authorName: nickname,
                            localAvatarPath: profile.avatarPath,
                            avatarUrl: profile.avatarUrl,
                            radius: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nickname,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View your profile',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.hintColor,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Section: Resources
            _buildSectionHeader(context, 'Resources'),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    theme: theme,
                    icon: Icons.menu_book_rounded,
                    title: 'Ilocano Bible',
                    subtitle: 'Read Holy Scriptures in Ilocano',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BibleScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildMenuItem(
                    theme: theme,
                    icon: Icons.description_outlined,
                    title: 'Church Bylaws',
                    subtitle: 'Read rules, principles, and regulations',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BylawsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Section: Tools & Support
            _buildSectionHeader(context, 'Tools & Support'),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: ChordsSettingsService.instance,
                    builder: (context, showChordsAndShapes, child) {
                      return ListTile(
                        leading: Icon(
                          Icons.queue_music_rounded,
                          size: 22,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                        title: const Text(
                          'Show Chords & Shapes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          showChordsAndShapes ? 'Enabled' : 'Disabled',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Switch(
                          value: showChordsAndShapes,
                          onChanged: (val) {
                            if (val) {
                              AdService().showRewardedAdDialog(
                                context: context,
                                title: 'Unlock Chords & Shapes',
                                content:
                                    'Watch a short video ad to enable chords & shapes display.',
                                onReward: () {
                                  ChordsSettingsService.instance
                                      .setShowChordsAndShapes(true);
                                },
                              );
                            } else {
                              ChordsSettingsService.instance
                                  .setShowChordsAndShapes(false);
                            }
                          },
                        ),
                      );
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildMenuItem(
                    theme: theme,
                    icon: Icons.star_outline_rounded,
                    title: 'Rate this App',
                    subtitle: 'Leave a review on Google Play Store',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                    onTap: () async {
                      try {
                        final InAppReview inAppReview = InAppReview.instance;
                        if (await inAppReview.isAvailable()) {
                          await inAppReview.requestReview();
                        } else {
                          await inAppReview.openStoreListing();
                        }
                      } catch (e) {
                        debugPrint('Error triggering rating review: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open store review page. Please try again later.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildMenuItem(
                    theme: theme,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Feedback',
                    subtitle: 'Contact support or submit inquiries',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpFeedbackScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildMenuItem(
                    theme: theme,
                    icon: Icons.settings_outlined,
                    title: 'Settings & Privacy',
                    subtitle: 'Preferences, Appearance, Account, Legal',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Section: Admin Panel (Conditional)
            ValueListenableBuilder<UserProfile>(
              valueListenable: UserService.instance,
              builder: (context, profile, child) {
                if (profile.memberId != 'USER1') {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Admin Panel'),
                    Card(
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            theme: theme,
                            icon: Icons.admin_panel_settings_rounded,
                            title: 'Helpline Tickets',
                            subtitle: 'Review and reply to user tickets',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminTicketsScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(color: theme.dividerColor, height: 1),
                          _buildMenuItem(
                            theme: theme,
                            icon: Icons.music_video_rounded,
                            title: 'Song Submissions',
                            subtitle: 'Review user song contributions',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminSongsScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(color: theme.dividerColor, height: 1),
                          _buildMenuItem(
                            theme: theme,
                            icon: Icons.edit_location_alt_rounded,
                            title: 'Center Updates',
                            subtitle: 'Review center edit suggestions',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminCenterUpdatesScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // Section: Community & Social
            _buildSectionHeader(context, 'Community'),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    theme: theme,
                    icon: Icons.facebook,
                    title: 'Official Facebook Page',
                    subtitle: 'Follow updates, broadcasts, and announcements',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                    onTap: () => _launchFacebookPage(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
