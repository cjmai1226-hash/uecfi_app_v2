import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';

class SuggestNewCenterScreen extends StatefulWidget {
  const SuggestNewCenterScreen({super.key});

  @override
  State<SuggestNewCenterScreen> createState() => _SuggestNewCenterScreenState();
}

class _SuggestNewCenterScreenState extends State<SuggestNewCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _facebookPageController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _addressController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final contactPerson = _contactNameController.text.trim();
    final contactNumber = _contactNumberController.text.trim();
    final facebookPage = _facebookPageController.text.trim();
    final mapsLink = _mapsLinkController.text.trim();
    final notes = _notesController.text.trim();
    final submittedBy = UserService.instance.value.email;

    final Map<String, dynamic> payload = {
      'contactPerson': contactPerson.isNotEmpty ? contactPerson : 'N/A',
      'contactNumber': contactNumber.isNotEmpty ? contactNumber : 'N/A',
      'facebookPage': facebookPage.isNotEmpty ? facebookPage : 'N/A',
      'mapsLink': mapsLink.isNotEmpty ? mapsLink : 'N/A',
      'notes': notes.isNotEmpty ? notes : 'N/A',
    };

    try {
      await FirestoreService().submitCenterUpdate(
        centerId: 'new_worship_center',
        centerName: name,
        centerAddress: address,
        updateType: 'New Center Suggestion',
        payload: payload,
        submittedByEmail: submittedBy,
      );
      await FirestoreService().incrementUserContributions(submittedBy);
    } catch (e) {
      debugPrint('Error submitting new center suggestion: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! "$name" has been submitted for review.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _addressController.removeListener(_onTextChanged);
    _nameController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactNumberController.dispose();
    _facebookPageController.dispose();
    _mapsLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggest New Center'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed:
                (_isSubmitting ||
                    _nameController.text.trim().isEmpty ||
                    _addressController.text.trim().isEmpty)
                ? null
                : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                : Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          (_nameController.text.trim().isEmpty ||
                              _addressController.text.trim().isEmpty)
                          ? theme.disabledColor
                          : (theme.brightness == Brightness.dark
                                ? Colors.white
                                : theme.colorScheme.primary),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help build our directory by suggesting a local Worship Center that is missing from the list.',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Center Name Field
                Text(
                  'Center Name *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'e.g. JEZRAEL'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the center name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Center Address Field
                Text(
                  'Center Address *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 123 Street Name, Caloocan City',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the center address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contact Person Field
                Text(
                  'Contact Person (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Juan Dela Cruz',
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Number Field
                Text(
                  'Contact Number (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 0917XXXXXXX',
                  ),
                ),
                const SizedBox(height: 16),

                // Facebook Page Field
                Text(
                  'Facebook Page Link (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _facebookPageController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. https://facebook.com/uecfiname',
                  ),
                ),
                const SizedBox(height: 16),

                // Maps Link Field
                Text(
                  'Google Maps Link / Coordinates (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _mapsLinkController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. https://maps.google.com/?q=...',
                  ),
                ),
                const SizedBox(height: 16),

                // Additional Notes Field
                Text(
                  'Additional Notes (Optional)',
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
                    hintText: 'Add schedule, directions or details here...',
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
