import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';

class SubmitSongScreen extends StatefulWidget {
  const SubmitSongScreen({super.key});

  @override
  State<SubmitSongScreen> createState() => _SubmitSongScreenState();
}

class _SubmitSongScreenState extends State<SubmitSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _lyricsController = TextEditingController();

  String _selectedCategory = 'Worship';
  final List<String> _categoryOptions = [
    'Worship',
    'Praise',
    'Hymns',
    'Offertory',
    'Gospel',
    'Fellowship',
    'Other',
  ];

  bool _isSubmitting = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final author = _authorController.text.trim().isEmpty ? 'Unknown' : _authorController.text.trim();
    final category = _selectedCategory;
    final lyrics = _lyricsController.text.trim();
    final submittedBy = UserService.instance.value.email;

    try {
      await FirestoreService().submitSongSuggestion(
        title: title,
        author: author,
        category: category,
        lyrics: lyrics,
        chords: '',
        submittedByEmail: submittedBy,
      );
    } catch (e) {
      debugPrint('Error submitting song to Firestore: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thank you! "$title" has been submitted for review.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Worship Song'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Song Title Field
              Text(
                'Song Title *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Amazing Grace',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the song title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author / Composer Field
              Text(
                'Author / Composer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  hintText: 'e.g. John Newton',
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Text(
                'Category',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: _categoryOptions.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Lyrics Field
              Text(
                'Lyrics & Chords *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lyricsController,
                maxLines: 8,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter complete lyrics line-by-line...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the song lyrics';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button (XL Material 3 Button)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Song',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
