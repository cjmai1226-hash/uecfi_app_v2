import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/center_model.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';

class CenterDetailScreen extends StatelessWidget {
  final CenterModel center;

  const CenterDetailScreen({
    super.key,
    required this.center,
  });

  String _capitalize(String text) {
    if (text.trim().isEmpty) return '';
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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

  Future<void> _openMapsUrl(BuildContext context, String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Get Directions'),
          content: Text('Would you like to open Google Maps to navigate to ${center.name}?'),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      _openSuggestEditModal(context, initialType: 'Location Locator');
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            SnackBar(content: Text('Could not launch phone dialer for $phoneNumber')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dialing number: $e')),
        );
      }
    }
  }

  void _openSuggestEditModal(BuildContext context, {String initialType = 'Location Locator'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SuggestEditSheet(center: center, initialType: initialType),
    );
  }

  Widget _buildFacebookIntroRow({
    required ThemeData theme,
    required IconData icon,
    String? prefixText,
    required String boldText,
    String? suffixText,
    Color? suffixColor,
    VoidCallback? onTap,
  }) {
    final row = Row(
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
                if (prefixText != null)
                  TextSpan(text: prefixText),
                TextSpan(
                  text: boldText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (suffixText != null)
                  TextSpan(
                    text: suffixText,
                    style: TextStyle(
                      color: suffixColor ?? theme.textTheme.bodySmall?.color,
                      fontWeight: suffixColor != null ? FontWeight.bold : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      );
    }
    return row;
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
                  height: 120,
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
                      opacity: 0.18,
                    ),
                  ),
                ),
                // Overlapping Center Avatar
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
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      child: Text(
                        center.name.isNotEmpty ? center.name[0].toUpperCase() : 'W',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50), // Spacer for overlapping avatar

            // Worship Center details body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center Name
                  Text(
                    center.name.isNotEmpty ? center.name : 'UECFI Worship Center',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Header Badges: Area Only
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (center.area.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            center.area.startsWith('Area') ? center.area : 'Area ${center.area}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                    icon: Icons.place_rounded,
                    prefixText: 'Worships at ',
                    boldText: center.address.isNotEmpty
                        ? center.address
                        : 'No address listed for this center.',
                    suffixText: center.address.isNotEmpty ? ' • Get Directions' : null,
                    suffixColor: theme.colorScheme.primary,
                    onTap: center.address.isNotEmpty ? () => _handleGetDirections(context) : null,
                  ),
                  const SizedBox(height: 14),
                  _buildFacebookIntroRow(
                    theme: theme,
                    icon: Icons.contact_phone_rounded,
                    prefixText: center.contact.isNotEmpty ? 'Contact: ' : null,
                    boldText: center.contact.isNotEmpty
                        ? center.contact
                        : 'No Contact Person added yet.',
                    suffixText: center.contact.isNotEmpty
                        ? (phoneNumber != null ? ' • Call Center' : ' • Suggest Edit')
                        : ' • Suggest Edit',
                    suffixColor: theme.colorScheme.primary,
                    onTap: () {
                      if (center.contact.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Contact Options'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(center.contact, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (phoneNumber != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Phone number: $phoneNumber', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                ],
                              ],
                            ),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        _openSuggestEditModal(context, initialType: 'Contact Person');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Suggest Edit'),
                                    ),
                                  ),
                                  if (phoneNumber != null) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                          _launchPhone(context, phoneNumber);
                                        },
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text('Call'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        _openSuggestEditModal(context, initialType: 'Contact Person');
                      }
                    },
                  ),
                  if (center.district.isNotEmpty || center.area.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildFacebookIntroRow(
                      theme: theme,
                      icon: Icons.map_rounded,
                      prefixText: 'Located in: ',
                      boldText: [
                        if (center.district.isNotEmpty) center.district,
                        if (center.area.isNotEmpty)
                          (center.area.startsWith('Area') ? center.area : 'Area ${center.area}'),
                      ].join(' • '),
                    ),
                  ],
                  if (center.status.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildFacebookIntroRow(
                      theme: theme,
                      icon: Icons.info_outline_rounded,
                      prefixText: 'Status: ',
                      boldText: center.status,
                    ),
                  ],

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
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
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
                    future: FirestoreService().getCenterMembers(center.name, center.address),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final List<Map<String, dynamic>> members = snapshot.data ?? [];

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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final String rawFirstName = member['firstName'] ?? '';
                                final String rawSurname = member['surname'] ?? '';
                                final String nickname = member['name'] ?? '';
                                
                                final String rawPosition = member['position'] ?? '';
                                final String positionVal = rawPosition.trim().isEmpty ? 'Member' : rawPosition.trim();

                                final String firstName = _capitalize(rawFirstName);
                                final String surname = _capitalize(rawSurname);
                                final String position = _capitalize(positionVal);
                                
                                final String fullName = '$firstName $surname'.trim();
                                final String displayName = fullName.isNotEmpty ? fullName : _capitalize(nickname);
                                final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';
                                final bool isDevChristian = nickname.toLowerCase() == 'devchristian';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      child: isDevChristian
                                          ? Padding(
                                              padding: const EdgeInsets.all(3.0),
                                              child: ClipOval(
                                                child: Image.asset(
                                                  'assets/images/brand_mark.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              initial,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                    ),
                                    title: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      nickname.isNotEmpty ? '$position • @$nickname' : position,
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                    ),
                                  ),
                                );
                              },
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

class _SuggestEditSheet extends StatefulWidget {
  final CenterModel center;
  final String initialType;

  const _SuggestEditSheet({
    required this.center,
    this.initialType = 'Location Locator',
  });

  @override
  State<_SuggestEditSheet> createState() => _SuggestEditSheetState();
}

class _SuggestEditSheetState extends State<_SuggestEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  final List<String> _informationTypes = [
    'Location Locator',
    'Contact Person',
    'Center History',
  ];

  // Location Locator Controllers
  final TextEditingController _latLngController = TextEditingController();
  final TextEditingController _mapsLinkController = TextEditingController();

  // Contact Person Controllers
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactRoleController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  // Center History Controller
  final TextEditingController _historyTextController = TextEditingController();

  // Common Additional Notes Controller
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = _informationTypes.contains(widget.initialType)
        ? widget.initialType
        : 'Location Locator';
  }

  @override
  void dispose() {
    _latLngController.dispose();
    _mapsLinkController.dispose();
    _contactNameController.dispose();
    _contactRoleController.dispose();
    _contactNumberController.dispose();
    _historyTextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop();

    final Map<String, dynamic> payload = {};
    if (_selectedType == 'Location Locator') {
      payload['latLng'] = _latLngController.text.trim();
      payload['mapsLink'] = _mapsLinkController.text.trim();
    } else if (_selectedType == 'Contact Person') {
      payload['contactName'] = _contactNameController.text.trim();
      payload['contactRole'] = _contactRoleController.text.trim();
      payload['contactNumber'] = _contactNumberController.text.trim();
    } else if (_selectedType == 'Center History') {
      payload['historyText'] = _historyTextController.text.trim();
    }
    payload['notes'] = _notesController.text.trim();

    final submittedBy = UserService.instance.value.email;

    try {
      await FirestoreService().submitCenterUpdate(
        centerId: widget.center.name,
        centerName: widget.center.name,
        centerAddress: widget.center.address,
        updateType: _selectedType,
        payload: payload,
        submittedByEmail: submittedBy,
      );
    } catch (e) {
      debugPrint('Error submitting center update to Firestore: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! Your edit suggestion for ${_selectedType.toLowerCase()} has been submitted for review.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildLocationFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latitude / Longitude',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _latLngController,
          decoration: const InputDecoration(
            hintText: 'e.g. 14.5995, 120.9842',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter latitude and longitude';
            }
            final regExp = RegExp(
              r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$'
            );
            if (!regExp.hasMatch(val.trim())) {
              return 'Please enter valid coordinates (e.g. 14.5995, 120.9842)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Google Maps Link',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _mapsLinkController,
          decoration: const InputDecoration(
            hintText: 'e.g. https://maps.app.goo.gl/...',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter a Google Maps link';
            }
            final uri = Uri.tryParse(val.trim());
            if (uri == null || !uri.hasScheme || !uri.host.contains('.')) {
              return 'Please enter a valid link (e.g. https://maps.app.goo.gl/...)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Name',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contactNameController,
          decoration: const InputDecoration(
            hintText: 'e.g. Pastor Juan Dela Cruz',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter contact name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Role / Position',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contactRoleController,
          decoration: const InputDecoration(
            hintText: 'e.g. Head Pastor, Secretary, Admin',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Contact Number',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contactNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'e.g. 0917 123 4567',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter a contact number';
            }
            final regExp = RegExp(r'^\+?[0-9\s\-()]{7,18}$');
            if (!regExp.hasMatch(val.trim())) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHistoryFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested History Text',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _historyTextController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Provide details about the founding, milestones, or history of this center...',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter history details';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Suggest Edit',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                widget.center.name,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
  
              // Information Type Dropdown
              Text(
                'Information Type',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: _informationTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
  
              // Dynamic Form Fields based on selection
              if (_selectedType == 'Location Locator') _buildLocationFields(theme),
              if (_selectedType == 'Contact Person') _buildContactFields(theme),
              if (_selectedType == 'Center History') _buildHistoryFields(theme),
  
              const SizedBox(height: 16),
  
              // Additional Notes Input Field
              Text(
                'Additional Notes',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any extra details or remarks for the district admin...',
                ),
              ),
              const SizedBox(height: 24),
  
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _submitSuggestion,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Submit Suggestion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
