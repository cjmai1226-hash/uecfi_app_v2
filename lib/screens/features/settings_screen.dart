import 'package:flutter/material.dart';
import '../../services/prayer_language_service.dart';
import '../../services/chords_settings_service.dart';
import '../../services/theme_service.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../services/notifications_settings_service.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedThemeMode = 'system';

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = _themeModeToString(ThemeService.instance.value);
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
        _selectedThemeMode = _themeModeToString(ThemeService.instance.value);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!recoverFormKey.currentState!.validate()) return;

                          final emailText = emailController.text.trim();
                          final enteredFirstName = firstNameController.text.trim();
                          final enteredMiddleName = middleNameController.text.trim();
                          final enteredSurname = surnameController.text.trim();
                          final enteredCenter = centerController.text.trim();
                          final enteredMemberId = memberIdController.text.trim();

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            final profileData = await FirestoreService().getUserProfile(emailText);
                            if (profileData != null) {
                              final dbFirstName = profileData['firstName']?.toString().trim() ?? '';
                              final dbMiddleName = profileData['middleName']?.toString().trim() ?? '';
                              final dbSurname = profileData['surname']?.toString().trim() ?? '';
                              final dbCenterName = profileData['centerName']?.toString().trim() ?? '';
                              final dbMemberId = profileData['uid']?.toString().trim() ?? '';

                              final isMatch = enteredFirstName.toLowerCase() == dbFirstName.toLowerCase() &&
                                  enteredMiddleName.toLowerCase() == dbMiddleName.toLowerCase() &&
                                  enteredSurname.toLowerCase() == dbSurname.toLowerCase() &&
                                  enteredCenter.toLowerCase() == dbCenterName.toLowerCase() &&
                                  enteredMemberId.toLowerCase() == dbMemberId.toLowerCase();

                              if (!isMatch) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Verification failed. Details do not match the registered account.'),
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

                              final nickname = profileData['name']?.toString() ?? 'Member';
                              final district = profileData['district']?.toString() ?? 'Default District';
                              final area = profileData['area']?.toString() ?? 'Default Area';
                              final centerAddress = profileData['centerAddress']?.toString() ?? '';
                              final memberId = profileData['uid']?.toString() ?? '';
                              final position = profileData['position']?.toString() ?? 'Member';

                              await UserService.instance.updateProfile(
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
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile verified and recovered successfully!'),
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
                                    content: Text('No profile found for this email address.'),
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
                                SnackBar(content: Text('Failed to recover profile: $e')),
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
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                      leading: Icon(
                        Icons.translate_rounded,
                        color: isSelected ? theme.colorScheme.primary : theme.hintColor,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final modes = ['system', 'light', 'dark'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                      leading: Icon(
                        mode == 'dark'
                            ? Icons.dark_mode_rounded
                            : mode == 'light'
                                ? Icons.light_mode_rounded
                                : Icons.brightness_auto_rounded,
                        color: isSelected ? theme.colorScheme.primary : theme.hintColor,
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
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
        padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      );
    }

    Widget buildSettingsRow({
      required IconData icon,
      required String title,
      Widget? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      return ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Icon(
          icon,
          size: 24,
          color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: subtitle,
        trailing: trailing,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader('Preferences'),
            
            // Prayer Language Selector row
            ValueListenableBuilder<String>(
              valueListenable: PrayerLanguageService.instance,
              builder: (context, langCode, child) {
                return buildSettingsRow(
                  icon: Icons.translate_rounded,
                  title: 'Prayer Language',
                  subtitle: Text(
                    langCode == 'TAG' ? 'Tagalog (TAG)' : 'Ilocano (ILO)',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
                  onTap: _showLanguageBottomSheet,
                );
              },
            ),

            // App Notifications Switch row
            ValueListenableBuilder<bool>(
              valueListenable: NotificationsSettingsService.instance,
              builder: (context, enabled, child) {
                return buildSettingsRow(
                  icon: Icons.notifications_rounded,
                  title: 'App Notifications',
                  subtitle: Text(
                    enabled ? 'Enabled' : 'Disabled',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Switch(
                    value: enabled,
                    onChanged: (val) {
                      NotificationsSettingsService.instance.setNotificationsEnabled(val);
                    },
                  ),
                );
              },
            ),

            // Show Chords and Shapes Switch row
            ValueListenableBuilder<bool>(
              valueListenable: ChordsSettingsService.instance,
              builder: (context, showChordsAndShapes, child) {
                return buildSettingsRow(
                  icon: Icons.queue_music_rounded,
                  title: 'Show Chords & Shapes',
                  subtitle: Text(
                    showChordsAndShapes ? 'Enabled' : 'Disabled',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Switch(
                    value: showChordsAndShapes,
                    onChanged: (val) {
                      ChordsSettingsService.instance.setShowChordsAndShapes(val);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            buildSectionHeader('Appearance'),

            // Theme Mode selector row (Opens Bottom Sheet)
            buildSettingsRow(
              icon: Icons.dark_mode_rounded,
              title: 'Appearance',
              subtitle: Text(
                _selectedThemeMode[0].toUpperCase() + _selectedThemeMode.substring(1),
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              onTap: _showAppearanceBottomSheet,
            ),

            const SizedBox(height: 12),

            buildSectionHeader('Account'),

            buildSettingsRow(
              icon: Icons.cloud_download_rounded,
              title: 'Recover Profile',
              subtitle: const Text(
                'Restore your profile details from the cloud',
                style: TextStyle(fontSize: 12),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              onTap: _showRecoverProfileDialog,
            ),

            const SizedBox(height: 12),

            buildSectionHeader('Legal & About'),

            buildSettingsRow(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              onTap: () => _showFeatureDialog(
                'Terms of Service',
                'Welcome to UECFI APP. By using this application, you agree to comply with and be bound by our terms of service, ensuring respectful communication and appropriate content sharing.',
              ),
            ),

            buildSettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              onTap: () => _showFeatureDialog(
                'Privacy Policy',
                'Your privacy is important to us. UECFI APP secures your profile information and local storage details. We do not sell or distribute user data to third parties.',
              ),
            ),

            buildSettingsRow(
              icon: Icons.group_outlined,
              title: 'Community Standards',
              trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              onTap: () => _showFeatureDialog(
                'Community Standards',
                'UECFI APP is built on love, faith, and fellowship. We expect all community members to post supportive material, refrain from hate speech, and follow church guiding principles.',
              ),
            ),

            buildSettingsRow(
              icon: Icons.info_outline_rounded,
              title: 'About',
              trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
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
