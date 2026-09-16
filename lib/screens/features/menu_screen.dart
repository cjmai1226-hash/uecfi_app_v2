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
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.8,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required ThemeData theme,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
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
            // Profile Tile at Top
            ValueListenableBuilder<UserProfile>(
              valueListenable: UserService.instance,
              builder: (context, profile, child) {
                final nickname = profile.nickname.isNotEmpty
                    ? profile.nickname
                    : 'Member';
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfileScreen(showAppBar: true),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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
                );
              },
            ),

            const SizedBox(height: 6),
            Divider(color: theme.dividerColor, height: 1),

            // Section: Resources
            _buildSectionHeader(context, 'Resources'),
            _buildMenuItem(
              theme: theme,
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
            _buildMenuItem(
              theme: theme,
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

            const SizedBox(height: 8),
            Divider(color: theme.dividerColor, height: 1),

            // Section: Tools & Support
            _buildSectionHeader(context, 'Tools & Support'),
            ValueListenableBuilder<bool>(
              valueListenable: ChordsSettingsService.instance,
              builder: (context, showChordsAndShapes, child) {
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  title: const Text(
                    'Show Chords & Shapes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    showChordsAndShapes ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
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
            _buildMenuItem(
              theme: theme,
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
            _buildMenuItem(
              theme: theme,
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
            _buildMenuItem(
              theme: theme,
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

            const SizedBox(height: 8),
            Divider(color: theme.dividerColor, height: 1),

            // Section: Community & Social
            _buildSectionHeader(context, 'Community'),
            _buildMenuItem(
              theme: theme,
              title: 'Official Facebook Page',
              subtitle: 'Follow updates, broadcasts, and announcements',
              trailing: const Icon(
                Icons.open_in_new_rounded,
                size: 18,
              ),
              onTap: () => _launchFacebookPage(context),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
