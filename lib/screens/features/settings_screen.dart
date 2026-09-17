import 'package:flutter/material.dart';
import '../../services/prayer_language_service.dart';
import '../../services/theme_service.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../services/notifications_settings_service.dart';
import 'about_screen.dart';

import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedThemeMode = 'system';
  AppThemeColor _selectedThemeColor = AppThemeColor.electricViolet;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = _themeModeToString(ThemeService.instance.value.mode);
    _selectedThemeColor = ThemeService.instance.value.color;
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _selectedThemeMode = _themeModeToString(
          ThemeService.instance.value.mode,
        );
        _selectedThemeColor = ThemeService.instance.value.color;
      });
    }
  }

  ThemeMode _parseStringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  String _getThemeColorLabel(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.googleAI:
        return 'Gemini';
      case AppThemeColor.electricViolet:
        return 'Electric Violet';
    }
  }

  Color _getThemePrimaryColor(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.electricViolet:
        return const Color(0xFFA100FF);
      case AppThemeColor.googleAI:
        return const Color(0xFF1A73E8);
    }
  }

  void _showRecoverProfileDialog() {
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final surnameController = TextEditingController();
    final centerController = TextEditingController();
    final memberIdController = TextEditingController();
    final recoverFormKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Recover Profile'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: recoverFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provide the details below to verify and restore your profile from Firebase:',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Registered Email',
                            hintText: 'e.g. user@email.com',
                          ),
                          enabled: !isLoading,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            hintText: 'e.g. Juan',
                          ),
                          enabled: !isLoading,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: middleNameController,
                          decoration: const InputDecoration(
                            labelText: 'Middle Name (Optional)',
                            hintText: 'e.g. Ramos',
                          ),
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: surnameController,
                          decoration: const InputDecoration(
                            labelText: 'Surname / Last Name',
                            hintText: 'e.g. Dela Cruz',
                          ),
                          enabled: !isLoading,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your surname';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: centerController,
                          decoration: const InputDecoration(
                            labelText: 'Local Center',
                            hintText: 'e.g. Baguio City Center',
                          ),
                          enabled: !isLoading,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your local center';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: memberIdController,
                          decoration: const InputDecoration(
                            labelText: 'Member ID',
                            hintText: 'e.g. USER12345',
                          ),
                          enabled: !isLoading,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your member ID';
                            }
                            return null;
                          },
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!recoverFormKey.currentState!.validate()) return;

                          final emailText = emailController.text.trim();
                          final enteredFirstName = firstNameController.text
                              .trim();
                          final enteredMiddleName = middleNameController.text
                              .trim();
                          final enteredSurname = surnameController.text.trim();
                          final enteredCenter = centerController.text.trim();
                          final enteredMemberId = memberIdController.text
                              .trim();

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            final profileData = await FirestoreService()
                                .getUserProfile(emailText);
                            if (profileData != null) {
                              final dbFirstName =
                                  profileData['firstName']?.toString().trim() ??
                                  '';
                              final dbMiddleName =
                                  profileData['middleName']
                                      ?.toString()
                                      .trim() ??
                                  '';
                              final dbSurname =
                                  profileData['surname']?.toString().trim() ??
                                  '';
                              final dbCenterName =
                                  profileData['centerName']
                                      ?.toString()
                                      .trim() ??
                                  '';
                              final dbMemberId =
                                  profileData['uid']?.toString().trim() ?? '';

                              final isMatch =
                                  enteredFirstName.toLowerCase() ==
                                      dbFirstName.toLowerCase() &&
                                  enteredMiddleName.toLowerCase() ==
                                      dbMiddleName.toLowerCase() &&
                                  enteredSurname.toLowerCase() ==
                                      dbSurname.toLowerCase() &&
                                  enteredCenter.toLowerCase() ==
                                      dbCenterName.toLowerCase() &&
                                  enteredMemberId.toLowerCase() ==
                                      dbMemberId.toLowerCase();

                              if (!isMatch) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Verification failed. Details do not match the registered account.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                                setDialogState(() {
                                  isLoading = false;
                                });
                                return;
                              }

                              final nickname =
                                  profileData['name']?.toString() ?? 'Member';
                              final district =
                                  profileData['district']?.toString() ??
                                  'Default District';
                              final area =
                                  profileData['area']?.toString() ??
                                  'Default Area';
                              final centerAddress =
                                  profileData['centerAddress']?.toString() ??
                                  '';
                              final memberId =
                                  profileData['uid']?.toString() ?? '';
                              final position =
                                  profileData['position']?.toString() ??
                                  'Member';
                              final avatarUrl = profileData['avatarUrl']
                                  ?.toString();
                              final coverUrl = profileData['coverUrl']
                                  ?.toString();
                              final contributions =
                                  profileData['contributions'] as int? ?? 0;
                              final isLocked = profileData['isLocked'] == true;

                              await UserService.instance.restoreFullProfile(
                                nickname: nickname,
                                firstName: dbFirstName,
                                middleName: dbMiddleName,
                                lastName: dbSurname,
                                district: district,
                                area: area,
                                localCenter: dbCenterName,
                                centerAddress: centerAddress,
                                memberId: memberId,
                                email: emailText,
                                position: position,
                                avatarUrl: avatarUrl,
                                coverUrl: coverUrl,
                                contributions: contributions,
                                isLocked: isLocked,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile verified and recovered successfully!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No profile found for this email address.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              setDialogState(() {
                                isLoading = false;
                              });
                            }
                          } catch (e) {
                            debugPrint('Error recovering profile: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to recover profile: $e',
                                  ),
                                ),
                              );
                            }
                            setDialogState(() {
                              isLoading = false;
                            });
                          }
                        },
                  child: const Text('Verify & Recover'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Slide up modal bottom sheet to select prayer language
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final currentLang = PrayerLanguageService.instance.value;
            final options = [
              {'code': 'ILO', 'name': 'Ilocano (ILO)'},
              {'code': 'TAG', 'name': 'Tagalog (TAG)'},
            ];

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Language',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...options.map((opt) {
                      final code = opt['code']!;
                      final name = opt['name']!;
                      final isSelected = code == currentLang;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          PrayerLanguageService.instance.setLanguage(code);
                          setState(() {});
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Slide up modal bottom sheet to select appearance mode
  void _showAppearanceBottomSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final modes = ['system', 'light', 'dark'];
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance Mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...modes.map((mode) {
                      final isSelected = mode == _selectedThemeMode;
                      final label = mode[0].toUpperCase() + mode.substring(1);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          final themeMode = _parseStringToThemeMode(mode);
                          ThemeService.instance.setThemeMode(themeMode);
                          setState(() {
                            _selectedThemeMode = mode;
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Slide up modal bottom sheet to select theme color palette
  void _showThemeColorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colors = [
              {
                'color': AppThemeColor.electricViolet,
                'title': 'Electric Violet',
                'subtitle': 'Modern Electric Violet & Cyber Slate',
                'swatches': [
                  const Color(0xFFA100FF),
                  const Color(0xFF7500C0),
                  const Color(0xFF00E5FF),
                ],
              },
              {
                'color': AppThemeColor.googleAI,
                'title': 'Gemini',
                'subtitle': 'Royal Blue & Gemini Violet',
                'swatches': [
                  const Color(0xFF1A73E8),
                  const Color(0xFF7C3AED),
                  const Color(0xFFFF5E7E),
                ],
              },
            ];

            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Theme Color',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your preferred brand accent and interface color',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...colors.map((item) {
                        final themeColor = item['color'] as AppThemeColor;
                        final title = item['title'] as String;
                        final subtitle = item['subtitle'] as String;
                        final swatches = item['swatches'] as List<Color>;
                        final isSelected = themeColor == _selectedThemeColor;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: swatches.map((c) {
                                return Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              ThemeService.instance.setThemeColor(themeColor);
                              setState(() {
                                _selectedThemeColor = themeColor;
                              });
                              setModalState(() {});
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFeatureDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 16, bottom: 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
            letterSpacing: 0.8,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      );
    }

    Widget buildSettingsRow({
      required String title,
      Widget? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: subtitle,
        trailing:
            trailing ??
            Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Privacy'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader('Preferences'),
            ValueListenableBuilder<String>(
              valueListenable: PrayerLanguageService.instance,
              builder: (context, langCode, child) {
                return buildSettingsRow(
                  title: 'Prayer Language',
                  subtitle: Text(
                    langCode == 'TAG' ? 'Tagalog (TAG)' : 'Ilocano (ILO)',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  onTap: _showLanguageBottomSheet,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: NotificationsSettingsService.instance,
              builder: (context, enabled, child) {
                return buildSettingsRow(
                  title: 'App Notifications',
                  subtitle: Text(
                    enabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  trailing: Switch(
                    value: enabled,
                    onChanged: (val) {
                      NotificationsSettingsService.instance
                          .setNotificationsEnabled(val);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            Divider(color: theme.dividerColor, height: 1),

            buildSectionHeader('Appearance'),
            buildSettingsRow(
              title: 'Appearance Mode',
              subtitle: Text(
                _selectedThemeMode[0].toUpperCase() +
                    _selectedThemeMode.substring(1),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              onTap: _showAppearanceBottomSheet,
            ),
            buildSettingsRow(
              title: 'Theme Color',
              subtitle: Text(
                _getThemeColorLabel(_selectedThemeColor),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getThemePrimaryColor(_selectedThemeColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.hintColor,
                    size: 20,
                  ),
                ],
              ),
              onTap: _showThemeColorBottomSheet,
            ),

            const SizedBox(height: 8),
            Divider(color: theme.dividerColor, height: 1),

            buildSectionHeader('Account'),
            buildSettingsRow(
              title: 'Recover Profile',
              subtitle: Text(
                'Restore your profile details from the cloud',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              onTap: _showRecoverProfileDialog,
            ),

            const SizedBox(height: 8),
            Divider(color: theme.dividerColor, height: 1),

            buildSectionHeader('Legal & About'),
            buildSettingsRow(
              title: 'Terms of Service',
              onTap: () => _showFeatureDialog(
                'Terms of Service',
                'Welcome to UECFI APP. By using this application, you agree to comply with and be bound by our terms of service, ensuring respectful communication and appropriate content sharing.',
              ),
            ),
            buildSettingsRow(
              title: 'Privacy Policy',
              onTap: () => _showFeatureDialog(
                'Privacy Policy',
                'Your privacy is important to us. UECFI APP secures your profile information and local storage details. We do not sell or distribute user data to third parties.',
              ),
            ),
            buildSettingsRow(
              title: 'Community Standards',
              onTap: () => _showFeatureDialog(
                'Community Standards',
                'UECFI APP is built on love, faith, and fellowship. We expect all community members to post supportive material, refrain from hate speech, and follow church guiding principles.',
              ),
            ),
            buildSettingsRow(
              title: 'About',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
