import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../models/user_profile.dart';
import '../../services/ad_service.dart';
import '../../services/chords_settings_service.dart';
import '../../services/user_service.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/user_avatar.dart';
import '../history/uecfi_history_screen.dart';
import 'bible_screen.dart';
import 'bylaws_screen.dart';
import 'help_feedback_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  final bool showAppBar;

  const MenuScreen({super.key, this.showAppBar = false});

  Widget _buildSectionHeader({
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 1,
      color: borderColor,
      indent: 6,
      endIndent: 6,
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    List<List<dynamic>>? icon,
    Color? iconColor,
    Color? chevronColor,
    Widget? trailingWidget,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: icon != null
          ? AppIcon(
              icon: icon,
              color: iconColor ?? textPrimary,
              size: 24,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textSecondary,
          fontSize: 12.5,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) ...[
            trailingWidget,
            if (showChevron) const SizedBox(width: 4),
          ],
          if (showChevron)
            AppIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: chevronColor ?? textSecondary,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                'Menu',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 0,
              scrolledUnderElevation: 1,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            ValueListenableBuilder<UserProfile>(
              valueListenable: UserService.instance,
              builder: (context, profile, child) {
                final nickname = profile.nickname.isNotEmpty
                    ? profile.nickname
                    : 'Member';
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.20 : 0.02,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileScreen(showAppBar: true),
                          ),
                        );
                      },
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'View your profile',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Text(
                                      'MEMBER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section: Resources
            _buildSectionHeader(
              title: 'RESOURCES',
              color: textSecondary,
            ),
            const SizedBox(height: 6),
            _buildMenuItem(
              title: 'Ilocano Bible',
              subtitle: 'Read Holy Scriptures in Ilocano',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              icon: HugeIcons.strokeRoundedBookOpen01,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BibleScreen()),
                );
              },
            ),
            _buildDivider(borderColor),
            _buildMenuItem(
              title: 'Church Bylaws',
              subtitle: 'Read rules, principles, and regulations',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              icon: HugeIcons.strokeRoundedLegalDocument01,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BylawsScreen()),
                );
              },
            ),
            _buildDivider(borderColor),
            _buildMenuItem(
              title: 'UECFI History & Heritage',
              subtitle: 'Origins, pioneers, and founding story',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              icon: HugeIcons.strokeRoundedBook02,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UecfiHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section: Tools & Support
            _buildSectionHeader(
              title: 'TOOLS & SUPPORT',
              color: textSecondary,
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<bool>(
              valueListenable: ChordsSettingsService.instance,
              builder: (context, showChordsAndShapes, child) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: AppIcon(
                    icon: HugeIcons.strokeRoundedMusic02,
                    color: textPrimary,
                    size: 24,
                  ),
                  title: Text(
                    'Show Chords & Shapes',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    showChordsAndShapes ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5,
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
                        ChordsSettingsService.instance.setShowChordsAndShapes(
                          false,
                        );
                      }
                    },
                  ),
                );
              },
            ),
            _buildDivider(borderColor),
            _buildMenuItem(
              title: 'Rate this App',
              subtitle: 'Leave a review on Google Play Store',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              icon: HugeIcons.strokeRoundedStar,
              trailingWidget: AppIcon(
                icon: HugeIcons.strokeRoundedArrowUpRight01,
                size: 18,
                color: textSecondary,
              ),
              showChevron: false,
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
            _buildDivider(borderColor),
            _buildMenuItem(
              title: 'Help & Feedback',
              subtitle: 'Contact support or submit inquiries',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              icon: HugeIcons.strokeRoundedHelpCircle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HelpFeedbackScreen(),
                  ),
                );
              },
            ),
            _buildDivider(borderColor),
            _buildMenuItem(
              title: 'Settings & Privacy',
              subtitle: 'Preferences, Appearance, Account, Legal',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              icon: HugeIcons.strokeRoundedSettings01,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
