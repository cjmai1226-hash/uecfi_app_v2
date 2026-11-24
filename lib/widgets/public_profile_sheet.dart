import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_icon.dart';
import 'user_avatar.dart';
import '../utils/theme.dart';

/// A simplified, modern Material 3 Bottom Sheet displaying a public member's
/// profile photo, nickname, and church center.
class PublicProfileSheet extends StatefulWidget {
  final String userEmail;
  final String? initialNickname;
  final String? initialAvatarUrl;
  final String? initialLocalCenter;
  final String? initialCenterAddress;

  const PublicProfileSheet({
    super.key,
    required this.userEmail,
    this.initialNickname,
    this.initialAvatarUrl,
    this.initialLocalCenter,
    this.initialCenterAddress,
  });

  /// Convenient helper to display the sheet modally.
  static Future<void> show(
    BuildContext context, {
    required String userEmail,
    String? initialNickname,
    String? initialAvatarUrl,
    String? initialLocalCenter,
    String? initialCenterAddress,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PublicProfileSheet(
        userEmail: userEmail,
        initialNickname: initialNickname,
        initialAvatarUrl: initialAvatarUrl,
        initialLocalCenter: initialLocalCenter,
        initialCenterAddress: initialCenterAddress,
      ),
    );
  }

  @override
  State<PublicProfileSheet> createState() => _PublicProfileSheetState();
}

class _PublicProfileSheetState extends State<PublicProfileSheet> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchLatestDetails();
  }

  Future<void> _fetchLatestDetails() async {
    final cleanEmail = widget.userEmail.trim().toLowerCase();

    try {
      DocumentSnapshot? doc;
      if (cleanEmail.isNotEmpty && cleanEmail.contains('@')) {
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cleanEmail)
            .get();
      }

      if (doc != null && doc.exists) {
        if (mounted) {
          setState(() {
            _userData = doc!.data() as Map<String, dynamic>;
          });
        }
        return;
      }

      // Fallback search by nickname if email was not provided or not matched
      final nickname = widget.initialNickname?.trim() ?? '';
      if (nickname.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: nickname)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty && mounted) {
          setState(() {
            _userData = query.docs.first.data();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching member details for bottom sheet: $e');
    }
  }

  void _showEnlargedPhoto(BuildContext context, String imageUrl, String name) {
    if (imageUrl.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const AppIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: AppIcon(
                      icon: HugeIcons.strokeRoundedImage01,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve display properties with fast fallback to initial values
    final String displayName = (_userData?['name'] as String?)?.isNotEmpty == true
        ? _userData!['name']
        : (widget.initialNickname ?? 'Member');

    final String? avatarUrl =
        (_userData?['avatarUrl'] as String?)?.isNotEmpty == true
            ? _userData!['avatarUrl']
            : widget.initialAvatarUrl;

    final String centerName =
        (_userData?['centerName'] as String?)?.isNotEmpty == true
            ? _userData!['centerName']
            : ((_userData?['localCenter'] as String?)?.isNotEmpty == true
                ? _userData!['localCenter']
                : (widget.initialLocalCenter ?? ''));

    final String rawDistrict = _userData?['district'] ?? '';
    final String district = rawDistrict.isNotEmpty
        ? (rawDistrict.toLowerCase().startsWith('district')
            ? rawDistrict
            : 'District $rawDistrict')
        : '';

    final String rawArea = _userData?['area'] ?? '';
    final String area = rawArea.isNotEmpty
        ? (rawArea.toLowerCase().startsWith('area') ? rawArea : 'Area $rawArea')
        : '';

    final String centerAddress =
        (_userData?['centerAddress'] as String?)?.isNotEmpty == true
            ? _userData!['centerAddress']
            : (widget.initialCenterAddress ?? '');

    final String position = _userData?['position'] ?? 'Member';
    final bool isLocked = _userData?['isLocked'] == true;
    final bool isDevChristian = displayName.toLowerCase() == 'devchristian';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF44474E) : const Color(0xFFE0E2EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Profile Header (Left: Photo, Right: Nickname & Role)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        _showEnlargedPhoto(context, avatarUrl, displayName);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.playBlue
                                  .withValues(alpha: isDark ? 0.4 : 0.25),
                              width: 2.5,
                            ),
                          ),
                          child: UserAvatar(
                            authorName: displayName,
                            avatarUrl: avatarUrl,
                            radius: 32,
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        if (avatarUrl != null && avatarUrl.isNotEmpty)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const AppIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Nickname (top) and Role / Position (below)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (isDevChristian) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.playBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const AppIcon(
                                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF004A77)
                                : AppTheme.playPrimaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            position,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.playDarkBlue
                                  : AppTheme.playOnPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Church Center Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1F20)
                      : const Color(0xFFF0F4F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.playBlue.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: AppIcon(
                          icon: HugeIcons.strokeRoundedChurch,
                          size: 22,
                          color: AppTheme.playBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            centerName.isNotEmpty ? centerName : 'Local Center Not Set',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: centerName.isNotEmpty
                                  ? context.contentColor
                                  : context.secondaryContentColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [district, area].where((s) => s.isNotEmpty).join(' • ').isNotEmpty
                                ? [district, area].where((s) => s.isNotEmpty).join(' • ')
                                : (centerName.isNotEmpty
                                    ? 'UECFI Member Center'
                                    : 'No center designated on profile'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.secondaryContentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (centerAddress.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1.5, right: 4),
                                  child: AppIcon(
                                    icon: HugeIcons.strokeRoundedLocation01,
                                    size: 13,
                                    color: context.secondaryContentColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    centerAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.secondaryContentColor,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Optional: Private Profile notice
              if (isLocked) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF332000) : const Color(0xFFFFF4E5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(
                        icon: HugeIcons.strokeRoundedLock,
                        size: 16,
                        color: Color(0xFFB06000),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This member has set their profile to private.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFFFB951) : const Color(0xFF663C00),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 7. Close / Done Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF282A2F) : const Color(0xFFE9EEF6),
                    foregroundColor: isDark ? AppTheme.textDark : AppTheme.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
