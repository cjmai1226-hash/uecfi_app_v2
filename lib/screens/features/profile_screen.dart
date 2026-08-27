import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../services/user_service.dart';
import '../../services/database_helper.dart';
import '../../models/user_profile.dart';
import '../../models/center_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/expandable_text.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _contributions = [];
  bool _isLoadingContributions = true;
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _fetchContributions();
  }

  Future<void> _fetchContributions() async {
    final email = UserService.instance.value.email;
    if (email.isEmpty) return;

    try {
      final items = await FirestoreService().getUserContributions(email);
      if (mounted) {
        setState(() {
          _contributions = items;
          _isLoadingContributions = false;
          _visibleCount = 10;
        });
      }
    } catch (e) {
      debugPrint('Error fetching contributions: $e');
      if (mounted) {
        setState(() {
          _isLoadingContributions = false;
        });
      }
    }
  }

  void _openEditProfilePage(BuildContext context, UserProfile currentProfile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentProfile: currentProfile),
      ),
    );
    _fetchContributions();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _confirmDeleteContribution(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final String type = item['type'] ?? '';
    final String id = item['id'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $type'),
          content: Text(
            'Are you sure you want to delete this $type? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteContribution(type, id);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showContributionOptions(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contribution Options',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete Contribution',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _confirmDeleteContribution(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteContribution(String type, String id) async {
    // Show loading indicator snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Deleting contribution...'),
          ],
        ),
        duration: Duration(days: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      if (type == 'Post') {
        await FirestoreService().deleteCommunityPost(id);
      } else if (type == 'Song Suggestion') {
        await FirestoreService().deleteSongSubmission(id);
      } else if (type == 'Center Update') {
        await FirestoreService().deleteCenterUpdate(id);
      }

      setState(() {
        _contributions.removeWhere((item) => item['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contribution deleted successfully.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete contribution: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          '${isAvatar ? "avatar" : "cover"}_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final File savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');

      if (isAvatar) {
        await UserService.instance.updateProfileImages(
          avatarPath: savedImage.path,
        );
      } else {
        await UserService.instance.updateProfileImages(
          coverPath: savedImage.path,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isAvatar ? "Profile picture" : "Cover photo"} updated successfully!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handlePhotoTap(bool isAvatar, UserProfile profile) {
    final imagePath = isAvatar ? profile.avatarPath : profile.coverPath;
    final hasPhoto = imagePath.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvatar ? 'Profile Photo' : 'Cover Photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (hasPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.visibility_rounded,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                  title: const Text('View Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewPhotoFullScreen(isAvatar, imagePath);
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
                title: Text(hasPhoto ? 'Change Photo' : 'Upload Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isAvatar);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewPhotoFullScreen(bool isAvatar, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                isAvatar ? 'Profile Photo' : 'Cover Photo',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: Hero(
                tag: isAvatar ? 'avatar_hero' : 'cover_hero',
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Member Profile'), elevation: 0)
          : null,
      body: ValueListenableBuilder<UserProfile>(
        valueListenable: UserService.instance,
        builder: (context, profile, child) {
          final nickname = profile.nickname.isNotEmpty
              ? profile.nickname
              : 'Member';
          final district = profile.district.isNotEmpty
              ? profile.district
              : 'District';
          final area = profile.area.isNotEmpty ? profile.area : 'Area';
          final localCenter = profile.localCenter.isNotEmpty
              ? profile.localCenter
              : 'Local Center';
          final centerAddress = profile.centerAddress;
          final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'M';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Facebook-style Cover & Avatar Header
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover photo placeholder (Facebook Blue header card or uploaded local image)
                    GestureDetector(
                      onTap: () => _handlePhotoTap(false, profile),
                      child: Hero(
                        tag: 'cover_hero',
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: profile.coverPath.isEmpty
                                ? LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            image: profile.coverPath.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(profile.coverPath)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profile.coverPath.isEmpty
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Add Cover Photo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Overlapping Profile Avatar
                    Positioned(
                      bottom: -40,
                      left: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () => _handlePhotoTap(true, profile),
                          child: Stack(
                            children: [
                              Hero(
                                tag: 'avatar_hero',
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: isDark
                                      ? const Color(0xFF3A3B3C)
                                      : const Color(0xFFE4E6EB),
                                  backgroundImage:
                                      nickname.toLowerCase() !=
                                              'devchristian' &&
                                          profile.avatarPath.isNotEmpty
                                      ? FileImage(File(profile.avatarPath))
                                      : null,
                                  child:
                                      nickname.toLowerCase() == 'devchristian'
                                      ? Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/brand_mark.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      : (profile.avatarPath.isEmpty
                                            ? Text(
                                                initial,
                                                style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              )
                                            : null),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50), // Spacer for overlapping avatar
                // Profile Details Name & Badge Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              nickname,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Free badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF3A3B3C)
                                  : const Color(0xFFE4E6EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Free',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UECFI Member App User',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Facebook-style wide "Edit Profile" Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _openEditProfilePage(context, profile),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF3A3B3C)
                                : const Color(0xFFE4E6EB),
                            foregroundColor: isDark
                                ? const Color(0xFFE4E6EB)
                                : const Color(0xFF050505),
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
                      ),
                      const SizedBox(height: 24),
                      Divider(color: theme.dividerColor, height: 1),
                      const SizedBox(height: 20),

                      // Facebook-style "Intro" Details section
                      Text(
                        'Intro',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFacebookIntroRow(
                        theme: theme,
                        icon: Icons.person_rounded,
                        prefixText: 'Full Name: ',
                        boldText:
                            '${profile.firstName} ${profile.middleName.isEmpty ? "" : "${profile.middleName} "}${profile.lastName}',
                      ),
                      const SizedBox(height: 14),
                      if (profile.memberId.isNotEmpty) ...[
                        _buildFacebookIntroRow(
                          theme: theme,
                          icon: Icons.badge_outlined,
                          prefixText: 'Member ID: ',
                          boldText: profile.memberId,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (profile.email.isNotEmpty) ...[
                        _buildFacebookIntroRow(
                          theme: theme,
                          icon: Icons.email_outlined,
                          prefixText: 'Email: ',
                          boldText: profile.email,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (profile.position.isNotEmpty) ...[
                        _buildFacebookIntroRow(
                          theme: theme,
                          icon: Icons.work_outline_rounded,
                          prefixText: 'Serves as ',
                          boldText: profile.position,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildFacebookIntroRow(
                        theme: theme,
                        icon: Icons.church_rounded,
                        prefixText: 'Local Center: ',
                        boldText: localCenter,
                      ),
                      const SizedBox(height: 14),
                      _buildFacebookIntroRow(
                        theme: theme,
                        icon: Icons.map_rounded,
                        prefixText: 'Member of ',
                        boldText: 'District $district • Area $area',
                      ),
                      if (centerAddress.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildFacebookIntroRow(
                          theme: theme,
                          icon: Icons.place_rounded,
                          prefixText: 'Worships at ',
                                  boldText: centerAddress,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Divider(color: theme.dividerColor, height: 1),
                      const SizedBox(height: 20),
                      // Contributions Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Contributions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isLoadingContributions && _contributions.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_contributions.length}',
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

                      if (_isLoadingContributions)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_contributions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF242526)
                                : const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 32,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No contributions yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submitted songs, center updates, or posts will appear here.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _contributions.length > _visibleCount
                              ? _visibleCount
                              : _contributions.length,
                          itemBuilder: (context, index) {
                            final item = _contributions[index];
                            final String type = item['type'] ?? '';
                            final String title = item['title'] ?? '';
                            final String subtitle = item['subtitle'] ?? '';
                            final DateTime timestamp =
                                item['timestamp'] as DateTime;
                            final String status = item['status'] ?? '';
                            final bool isExpiredPost = type == 'Post' && DateTime.now().difference(timestamp).inDays >= 5;

                            // Header initials helper
                            final initials = initial;

                            // Type-specific body formatting
                            Widget bodyWidget;
                            if (type == 'Post') {
                              bodyWidget = ExpandableText(
                                text: title,
                                style: theme.textTheme.bodyMedium,
                              );
                            } else if (type == 'Song Suggestion') {
                              bodyWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Suggested Worship Song',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (item['lyrics'] != null && (item['lyrics'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2A2B2C)
                                            : const Color(0xFFEAEBED),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['lyrics'] as String,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: theme.textTheme.bodyMedium?.color,
                                        ),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            } else {
                              bodyWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Suggested Center Update',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orangeAccent.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (item['details'] != null && (item['details'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2A2B2C)
                                            : const Color(0xFFEAEBED),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['details'] as String,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      backgroundImage: nickname.toLowerCase() !=
                                                  'devchristian' &&
                                              profile.avatarPath.isNotEmpty
                                          ? FileImage(File(profile.avatarPath))
                                          : null,
                                      child: nickname.toLowerCase() ==
                                              'devchristian'
                                          ? Padding(
                                              padding: const EdgeInsets.all(3.0),
                                              child: ClipOval(
                                                child: Image.asset(
                                                  'assets/images/brand_mark.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            )
                                          : (profile.avatarPath.isEmpty
                                              ? Text(
                                                  initials,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme.primary,
                                                  ),
                                                )
                                              : null),
                                    ),
                                    title: Text(
                                      nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            type,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '•',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 11),
                                          ),
                                          Text(
                                            _formatDate(timestamp),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 11),
                                          ),
                                          if (status.isNotEmpty) ...[
                                            Text(
                                              '•',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(fontSize: 11),
                                            ),
                                            Text(
                                              isExpiredPost
                                                  ? 'Expired'
                                                  : (status == 'pending'
                                                      ? 'Pending'
                                                      : (status == 'reported'
                                                          ? 'Reported'
                                                          : 'Active')),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isExpiredPost
                                                    ? Colors.grey.shade600
                                                    : (status == 'pending'
                                                        ? Colors.orange.shade800
                                                        : (status == 'reported'
                                                            ? Colors.red.shade800
                                                            : Colors.green.shade800)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.more_horiz_rounded,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      tooltip: 'Contribution options',
                                      onPressed: () =>
                                          _showContributionOptions(context, item),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, right: 16, bottom: 16),
                                    child: bodyWidget,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      if (_contributions.length > _visibleCount) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _visibleCount += 10;
                              });
                            },
                            icon: const Icon(Icons.expand_more_rounded, size: 18),
                            label: const Text(
                              'Load More',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFacebookIntroRow({
    required ThemeData theme,
    required IconData icon,
    String? prefixText,
    required String boldText,
    String? suffixText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
              ),
              children: [
                if (prefixText != null) TextSpan(text: prefixText),
                TextSpan(
                  text: boldText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (suffixText != null)
                  TextSpan(
                    text: suffixText,
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _districtController;
  late TextEditingController _areaController;
  late TextEditingController _localCenterController;
  late TextEditingController _centerAddressController;
  late TextEditingController _emailController;
  late TextEditingController _positionController;

  List<String> _districts = [];
  List<CenterModel> _centerOptions = [];
  String? _selectedDistrict;
  CenterModel? _selectedCenter;
  String? _selectedAreaDropdown;

  final List<String> _areaDropdownOptions = [
    'Area 1',
    'Area 2',
    'Area 3',
    'Area 4',
    'Area 5',
    'Area 6',
    'Custom / Enter Manually',
  ];

  bool _isManualDistrict = false;
  bool _isManualCenter = false;
  bool _isManualArea = false;
  bool _isLoadingDb = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.currentProfile.nickname,
    );
    _firstNameController = TextEditingController(
      text: widget.currentProfile.firstName,
    );
    _middleNameController = TextEditingController(
      text: widget.currentProfile.middleName,
    );
    _lastNameController = TextEditingController(
      text: widget.currentProfile.lastName,
    );
    _districtController = TextEditingController(
      text: widget.currentProfile.district,
    );
    _areaController = TextEditingController(text: widget.currentProfile.area);
    _localCenterController = TextEditingController(
      text: widget.currentProfile.localCenter,
    );
    _centerAddressController = TextEditingController(
      text: widget.currentProfile.centerAddress,
    );
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _positionController = TextEditingController(
      text: widget.currentProfile.position,
    );

    _initAreaDropdown();
    _loadDatabaseData();
  }

  void _initAreaDropdown() {
    final areaText = widget.currentProfile.area.trim();
    final cleanNum = areaText.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNum.isNotEmpty &&
        ['1', '2', '3', '4', '5', '6'].contains(cleanNum)) {
      _selectedAreaDropdown = 'Area $cleanNum';
    } else if (areaText.isNotEmpty) {
      _selectedAreaDropdown = 'Custom / Enter Manually';
      _isManualArea = true;
    }
  }

  Future<void> _loadDatabaseData() async {
    try {
      final districts = await DatabaseHelper.getDistricts();
      setState(() {
        _districts = districts;
        if (districts.contains(widget.currentProfile.district)) {
          _selectedDistrict = widget.currentProfile.district;
        } else if (widget.currentProfile.district.isNotEmpty) {
          _isManualDistrict = true;
        }
        _isLoadingDb = false;
      });

      if (_selectedDistrict != null) {
        final centers = await DatabaseHelper.getCentersForDistrict(
          _selectedDistrict,
        );
        setState(() {
          _centerOptions = centers;
          final matched = centers.where(
            (c) => c.name == widget.currentProfile.localCenter,
          );
          if (matched.isNotEmpty) {
            _selectedCenter = matched.first;
          } else if (widget.currentProfile.localCenter.isNotEmpty) {
            _isManualCenter = true;
          }
        });
      }
    } catch (_) {
      setState(() {
        _isLoadingDb = false;
      });
    }
  }

  Future<void> _onDistrictSelected(String? district) async {
    if (district == 'Other / Enter Manually') {
      setState(() {
        _isManualDistrict = true;
        _selectedDistrict = null;
        _districtController.clear();
        _centerOptions = [];
        _selectedCenter = null;
      });
      return;
    }

    setState(() {
      _isManualDistrict = false;
      _selectedDistrict = district;
      _districtController.text = district ?? '';
      _selectedCenter = null;
    });

    if (district != null && district.isNotEmpty) {
      final centers = await DatabaseHelper.getCentersForDistrict(district);
      setState(() {
        _centerOptions = centers;
      });
    } else {
      setState(() {
        _centerOptions = [];
      });
    }
  }

  void _onCenterSelected(CenterModel? center) {
    if (center == null) return;

    setState(() {
      _selectedCenter = center;
      _localCenterController.text = center.name;
      _centerAddressController.text = center.address;

      final rawArea = center.area.trim();
      if (rawArea.isNotEmpty) {
        final cleanNum = rawArea.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanNum.isNotEmpty &&
            ['1', '2', '3', '4', '5', '6'].contains(cleanNum)) {
          _selectedAreaDropdown = 'Area $cleanNum';
          _areaController.text = 'Area $cleanNum';
          _isManualArea = false;
        } else {
          _selectedAreaDropdown = 'Custom / Enter Manually';
          _areaController.text = rawArea;
          _isManualArea = true;
        }
      }
    });
  }

  void _saveProfile() async {
    final nickname = _nicknameController.text.trim().isEmpty
        ? 'Member'
        : _nicknameController.text.trim();

    if (nickname != widget.currentProfile.nickname) {
      try {
        final exists = await FirestoreService().checkNicknameExists(nickname);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Nickname is already taken. Please choose a different one.',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Error checking nickname: $e');
      }
    }
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final district = _districtController.text.trim();
    final area = _areaController.text.trim();
    final localCenter = _localCenterController.text.trim().toUpperCase();
    final centerAddress = _centerAddressController.text.trim();
    final email = _emailController.text.trim();
    final position = _positionController.text.trim().isEmpty
        ? 'Member'
        : _positionController.text.trim();

    UserService.instance.updateProfile(
      nickname: nickname,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      district: district,
      area: area,
      localCenter: localCenter,
      centerAddress: centerAddress,
      memberId: widget.currentProfile.memberId,
      email: email,
      position: position,
    );

    // Save profile online to Firestore
    try {
      await FirestoreService().saveUserProfile(
        uid: widget.currentProfile.memberId,
        email: email,
        name: nickname,
        firstName: firstName,
        middleName: middleName,
        surname: lastName,
        position: position,
        district: district,
        area: _extractDigits(area),
        centerName: localCenter,
        centerAddress: centerAddress,
      );
    } catch (e) {
      debugPrint('Error saving user profile update to Firestore: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _districtController.dispose();
    _areaController.dispose();
    _localCenterController.dispose();
    _centerAddressController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferred Nickname
            Text(
              'Preferred Nickname',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            // First Name
            Text(
              'First Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            // Middle Name
            Text(
              'Middle Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            // Last Name
            Text(
              'Last Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            // Email Address
            Text(
              'Email Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: const InputDecoration(
                helperText: 'Unique Email Address cannot be changed',
              ),
            ),
            const SizedBox(height: 16),

            // Position in Church
            Text(
              'Position in Church',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                hintText: 'e.g. Member, Pastor, Deacon, Choir',
              ),
            ),
            const SizedBox(height: 16),

            // District
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'District',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isManualDistrict = !_isManualDistrict;
                      if (_isManualDistrict) {
                        _selectedDistrict = null;
                        _districtController.clear();
                        _centerOptions = [];
                        _selectedCenter = null;
                        _localCenterController.clear();
                        _centerAddressController.clear();
                      }
                    });
                  },
                  child: Text(
                    _isManualDistrict ? 'Use Dropdown' : 'Enter Manually',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isManualDistrict || _isLoadingDb)
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(hintText: 'e.g. District 1'),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedDistrict,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: [
                  ..._districts.map(
                    (d) => DropdownMenuItem(value: d, child: Text(d)),
                  ),
                  const DropdownMenuItem(
                    value: 'Other / Enter Manually',
                    child: Text('Other / Enter Manually...'),
                  ),
                ],
                onChanged: _onDistrictSelected,
              ),
            const SizedBox(height: 16),

            // District check helper
            Builder(
              builder: (context) {
                final bool isDistrictSelected =
                    _isManualDistrict || _selectedDistrict != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Local Center
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Local Center',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        GestureDetector(
                          onTap: isDistrictSelected
                              ? () {
                                  setState(() {
                                    _isManualCenter = !_isManualCenter;
                                    if (_isManualCenter) {
                                      _selectedCenter = null;
                                      _localCenterController.clear();
                                      _centerAddressController.clear();
                                    }
                                  });
                                }
                              : null,
                          child: Text(
                            _isManualCenter ? 'Use Dropdown' : 'Enter Manually',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDistrictSelected
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_isManualCenter || _centerOptions.isEmpty)
                      TextFormField(
                        controller: _localCenterController,
                        enabled: isDistrictSelected,
                        decoration: InputDecoration(
                          hintText: !isDistrictSelected
                              ? 'Select a District first or enter manually'
                              : 'e.g. Central Worship Center',
                        ),
                      )
                    else
                      DropdownButtonFormField<CenterModel>(
                        initialValue: _selectedCenter,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: isDistrictSelected
                            ? _centerOptions
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            c.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            c.address,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList()
                            : null,
                        selectedItemBuilder: isDistrictSelected
                            ? (BuildContext context) {
                                return _centerOptions.map((c) {
                                  return Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }).toList();
                              }
                            : null,
                        onChanged: isDistrictSelected
                            ? _onCenterSelected
                            : null,
                      ),
                    const SizedBox(height: 16),

                    // Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Area',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        GestureDetector(
                          onTap: isDistrictSelected
                              ? () {
                                  setState(() {
                                    _isManualArea = !_isManualArea;
                                    if (_isManualArea) {
                                      _selectedAreaDropdown =
                                          'Custom / Enter Manually';
                                      _areaController.clear();
                                    }
                                  });
                                }
                              : null,
                          child: Text(
                            _isManualArea ? 'Use Dropdown' : 'Enter Manually',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDistrictSelected
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (!isDistrictSelected || !_isManualArea)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAreaDropdown,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: isDistrictSelected
                            ? _areaDropdownOptions
                                  .map(
                                    (opt) => DropdownMenuItem(
                                      value: opt,
                                      child: Text(opt),
                                    ),
                                  )
                                  .toList()
                            : null,
                        onChanged: isDistrictSelected
                            ? (val) {
                                if (val == 'Custom / Enter Manually') {
                                  setState(() {
                                    _selectedAreaDropdown = val;
                                    _isManualArea = true;
                                  });
                                } else if (val != null) {
                                  setState(() {
                                    _selectedAreaDropdown = val;
                                    _areaController.text = val;
                                  });
                                }
                              }
                            : null,
                      )
                    else
                      TextFormField(
                        controller: _areaController,
                        enabled: isDistrictSelected,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Area 1',
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Center Address
                    Text(
                      'Center Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _centerAddressController,
                      enabled: isDistrictSelected && _isManualCenter,
                      decoration: const InputDecoration(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDigits(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? match.group(0)! : text;
  }
}
