import 'dart:io';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../screens/features/profile_screen.dart';

class FeedComposerCard extends StatelessWidget {
  final String placeholderTemplate;
  final IconData icon;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const FeedComposerCard({
    super.key,
    required this.placeholderTemplate,
    required this.icon,
    required this.onTap,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile>(
      valueListenable: UserService.instance,
      builder: (context, profile, _) {
        final userNickname =
            profile.nickname.isNotEmpty ? profile.nickname : 'Member';
        final initial =
            userNickname.isNotEmpty ? userNickname[0].toUpperCase() : 'M';
        final hasAvatar = profile.avatarPath.isNotEmpty;
        final isDevChristian =
            userNickname.toLowerCase() == 'devchristian';

        final displayText = placeholderTemplate.contains('{name}')
            ? placeholderTemplate.replaceAll('{name}', userNickname)
            : placeholderTemplate;

        return Container(
          width: double.infinity,
          margin: margin,
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.6),
                width: 1,
              ),
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileScreen(showAppBar: true),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary,
                        backgroundImage: !isDevChristian && hasAvatar
                            ? FileImage(File(profile.avatarPath))
                            : null,
                        child: isDevChristian
                            ? Padding(
                                padding: const EdgeInsets.all(2.5),
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
                                      fontSize: 16,
                                    ),
                                  )
                                : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3A3B3C)
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          displayText,
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
