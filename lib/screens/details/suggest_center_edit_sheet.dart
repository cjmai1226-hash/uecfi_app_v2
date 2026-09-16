import 'package:flutter/material.dart';
import '../../models/center_model.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';

class SuggestCenterEditSheet extends StatefulWidget {
  final CenterModel center;
  final String initialType;

  const SuggestCenterEditSheet({
    super.key,
    required this.center,
    this.initialType = 'Location Locator',
  });

  @override
  State<SuggestCenterEditSheet> createState() => _SuggestCenterEditSheetState();
}

class _SuggestCenterEditSheetState extends State<SuggestCenterEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  final List<String> _informationTypes = [
    'Location Locator',
    'Contact Person',
    'Facebook Page',
    'Center History',
  ];

  // Location Locator Controllers
  final TextEditingController _latLngController = TextEditingController();
  final TextEditingController _mapsLinkController = TextEditingController();

  // Contact Person Controllers
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactRoleController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();

  // Facebook Page Controller
  final TextEditingController _facebookPageController = TextEditingController();

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
    if (widget.center.page.isNotEmpty) {
      _facebookPageController.text = widget.center.page;
    }
  }

  @override
  void dispose() {
    _latLngController.dispose();
    _mapsLinkController.dispose();
    _contactNameController.dispose();
    _contactRoleController.dispose();
    _contactNumberController.dispose();
    _facebookPageController.dispose();
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
    } else if (_selectedType == 'Facebook Page') {
      payload['facebookPage'] = _facebookPageController.text.trim();
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
      await FirestoreService().incrementUserContributions(submittedBy);
    } catch (e) {
      debugPrint('Error submitting center update to Firestore: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thank you! Your edit suggestion for ${_selectedType.toLowerCase()} has been submitted for review.',
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _latLngController,
          decoration: const InputDecoration(hintText: 'e.g. 14.5995, 120.9842'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter latitude and longitude';
            }
            final regExp = RegExp(
              r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$',
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contactNameController,
          decoration: const InputDecoration(hintText: 'e.g. Juan Dela Cruz'),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contactRoleController,
          decoration: const InputDecoration(
            hintText: 'e.g. Local President, Secretary, Admin',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Contact Number',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contactNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'e.g. 0917 123 4567'),
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

  Widget _buildFacebookPageFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Center Facebook Page Link',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _facebookPageController,
          decoration: const InputDecoration(
            hintText: 'e.g. https://facebook.com/uecfiname or fb.me/...',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter a Facebook page URL or link';
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _historyTextController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Provide details about the founding, milestones, or history of this center...',
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
      child: SafeArea(
        top: false,
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
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Information Type Dropdown
              Text(
                'Information Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
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
              if (_selectedType == 'Location Locator')
                _buildLocationFields(theme),
              if (_selectedType == 'Contact Person') _buildContactFields(theme),
              if (_selectedType == 'Facebook Page')
                _buildFacebookPageFields(theme),
              if (_selectedType == 'Center History') _buildHistoryFields(theme),

              const SizedBox(height: 16),

              // Additional Notes Input Field
              Text(
                'Additional Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Any extra details or remarks for the district admin...',
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
      ),
    );
  }
}
