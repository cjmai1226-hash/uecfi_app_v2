import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/center_model.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../features/profile_screen.dart';
import '../features/public_profile_screen.dart';
import 'suggest_center_edit_sheet.dart';
import '../../widgets/user_avatar.dart';

class CenterDetailScreen extends StatelessWidget {
  final CenterModel center;

  const CenterDetailScreen({super.key, required this.center});

  String _capitalize(String text) {
    if (text.trim().isEmpty) return '';
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Extract phone number digits from contact field (which may contain name, position, and number)
  String? _extractPhoneNumber(String contact) {
    if (contact.trim().isEmpty) return null;
    final match = RegExp(r'(\+?\d[\d\s\-\(\)]{6,}\d)').firstMatch(contact);
    if (match != null) {
      final rawNum = match.group(0)!;
      final cleanNum = rawNum.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanNum.length >= 7) {
        return cleanNum;
      }
    }
    // Fallback: extract all digits
    final digits = contact.replaceAll(RegExp(r'[^\d+]'), '');
    return digits.length >= 7 ? digits : null;
  }

  Future<void> _openExternalUrl(BuildContext context, String rawUrl) async {
    if (rawUrl.trim().isEmpty) return;
    String cleanUrl = rawUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final url = Uri.parse(cleanUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open page: $e')));
      }
    }
  }

  Future<void> _openMapsUrl(BuildContext context, String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open map: $e')));
      }
    }
  }

  void _handleGetDirections(BuildContext context) {
    final hasLocation = center.location.isNotEmpty;
    final hasAddress = center.address.isNotEmpty;

    if (hasLocation) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Get Directions'),
          content: Text(
            'Would you like to open Google Maps to navigate to ${center.name}?',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _openMapsUrl(context, center.location);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Open Maps'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Locate This Center'),
          content: Text(
            hasAddress
                ? '${center.name} is not properly located yet. You can suggest a location edit or proceed using the address.'
                : '${center.name} is not properly located yet. Please suggest a location edit.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _openSuggestEditModal(
                        context,
                        initialType: 'Location Locator',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Suggest Edit'),
                  ),
                ),
                if (hasAddress) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _openMapsUrl(context, center.address);
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Use Address'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone dialer for $phoneNumber'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error dialing number: $e')));
      }
    }
  }

  void _openSuggestEditModal(
    BuildContext context, {
    String initialType = 'Location Locator',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          SuggestCenterEditSheet(center: center, initialType: initialType),
    );
  }



  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDark = false,
    bool isDisabled = false,
  }) {
    final effectiveFgColor = isDisabled
        ? (isDark ? Colors.white38 : Colors.black38)
        : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505));
    final effectiveBgColor = isDark
        ? (isDisabled ? const Color(0xFF2A2B2C) : const Color(0xFF3A3B3C))
        : (isDisabled ? const Color(0xFFEEEEEE) : const Color(0xFFE4E6EB));

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: effectiveFgColor),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveFgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleCallAction(BuildContext context, String? phoneNumber) {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      _launchPhone(context, phoneNumber);
    } else {
      _openSuggestEditModal(
        context,
        initialType: 'Contact Person',
      );
    }
  }

  void _openMemberProfile(
    BuildContext context, {
    required String email,
    required String nickname,
    String? avatarUrl,
    String? localCenter,
  }) {
    final currentUser = UserService.instance.value;
    final isSelf = (email.isNotEmpty &&
            email.toLowerCase() == currentUser.email.toLowerCase()) ||
        (nickname.isNotEmpty &&
            nickname.toLowerCase() == currentUser.nickname.toLowerCase());

    if (isSelf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PublicProfileScreen(
            userEmail: email,
            initialNickname: nickname,
            initialAvatarUrl: avatarUrl,
            initialLocalCenter: localCenter ?? center.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phoneNumber = _extractPhoneNumber(center.contact);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Center Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Suggest Edit',
            onPressed: () => _openSuggestEditModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facebook-style Cover & Avatar Header for Worship Center
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover banner placeholder (Facebook Blue header card)
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/brand_mark.png'),
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                      opacity: 0.18,
                    ),
                  ),
                ),
                // Overlapping Center Avatar
                Positioned(
                  bottom: -60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 4.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: isDark
                            ? const Color(0xFF3A3B3C)
                            : const Color(0xFFE4E6EB),
                        child: Text(
                          center.name.isNotEmpty
                              ? center.name[0].toUpperCase()
                              : 'W',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70), // Spacer for overlapping avatar
            // Worship Center details body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center Name
                  Center(
                    child: Text(
                      center.name.isNotEmpty
                          ? center.name
                          : 'UECFI Worship Center',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Header Subtitle: District • Area • Status
                  if (center.district.isNotEmpty ||
                      center.area.isNotEmpty ||
                      center.status.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        [
                          if (center.district.isNotEmpty) center.district,
                          if (center.area.isNotEmpty)
                            center.area.startsWith('Area')
                                ? center.area
                                : 'Area ${center.area}',
                          if (center.status.isNotEmpty) center.status,
                        ].join(' • '),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Quick Action Buttons Row 1 (Call, Directions)
                  Row(
                    children: [
                      // Call Button
                      Expanded(
                        child: _buildActionButton(
                          theme: theme,
                          isDark: isDark,
                          isDisabled: phoneNumber == null,
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          onTap: () => _handleCallAction(context, phoneNumber),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Directions Button
                      Expanded(
                        child: _buildActionButton(
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.directions_rounded,
                          label: 'Directions',
                          onTap: () {
                            if (center.location.isNotEmpty ||
                                center.address.isNotEmpty) {
                              _handleGetDirections(context);
                            } else {
                              _openSuggestEditModal(
                                context,
                                initialType: 'Location Locator',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick Action Buttons Row 2 (Visit)
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      theme: theme,
                      isDark: isDark,
                      icon: Icons.facebook,
                      label: 'Visit',
                      onTap: () {
                        if (center.page.isNotEmpty) {
                          _openExternalUrl(context, center.page);
                        } else {
                          _openSuggestEditModal(
                            context,
                            initialType: 'Facebook Page',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Standard Grouped Card "Intro" Details section
                  Text(
                    'Intro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.place_rounded),
                          title: Text(
                            center.address.isNotEmpty
                                ? center.address
                                : 'No address shared for this center yet.',
                            style: TextStyle(
                              fontWeight: center.address.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: center.address.isNotEmpty
                              ? const Text(
                                  'Address / Location',
                                  style: TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                        Divider(color: theme.dividerColor, height: 1),
                        ListTile(
                          leading: const Icon(Icons.contact_phone_rounded),
                          title: Text(
                            center.contact.isNotEmpty
                                ? center.contact
                                : 'No contact shared for this center yet.',
                            style: TextStyle(
                              fontWeight: center.contact.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: center.contact.isNotEmpty
                              ? const Text(
                                  'Contact Person',
                                  style: TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                        Divider(color: theme.dividerColor, height: 1),
                        ListTile(
                          leading: const Icon(Icons.facebook),
                          title: Text(
                            center.page.isNotEmpty
                                ? 'Official Facebook Page'
                                : 'No Facebook page shared for this center yet.',
                            style: TextStyle(
                              fontWeight: center.page.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: center.page.isNotEmpty
                              ? Text(
                                  center.page,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: center.page.isNotEmpty
                              ? const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                )
                              : null,
                          onTap: center.page.isNotEmpty
                              ? () => _openExternalUrl(context, center.page)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Center History Section
                  Text(
                    'Center History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (center.history.isNotEmpty)
                    Text(
                      center.history,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.textTheme.bodyLarge?.color?.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    )
                  else
                    Text(
                      'No history shared for this center yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 20),

                  // Center Members Section
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: FirestoreService().getCenterMembers(
                      center.name,
                      center.address,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final List<Map<String, dynamic>> members =
                          snapshot.data ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Members',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (members.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${members.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (members.isEmpty)
                            Text(
                              'No registered members at this center yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            )
                          else
                            Card(
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: members.length,
                                separatorBuilder: (context, index) =>
                                    Divider(color: theme.dividerColor, height: 1),
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final String nickname = member['name'] ?? '';
                                  final String rawPosition =
                                      member['position'] ?? '';
                                  final String positionVal =
                                      rawPosition.trim().isEmpty
                                      ? 'Member'
                                      : rawPosition.trim();
                                  final String position = _capitalize(
                                    positionVal,
                                  );
                                  final String displayName = nickname.isNotEmpty
                                      ? _capitalize(nickname)
                                      : 'Member';
                                  final bool isDevChristian =
                                      nickname.toLowerCase() == 'devchristian';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    onTap: () => _openMemberProfile(
                                      context,
                                      email: member['email'] ?? '',
                                      nickname: nickname,
                                      avatarUrl: member['avatarUrl'] as String?,
                                      localCenter: center.name,
                                    ),
                                    leading: UserAvatar(
                                      authorName: displayName,
                                      avatarUrl: member['avatarUrl'] as String?,
                                      radius: 20,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (isDevChristian) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.verified_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 15,
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      position,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
