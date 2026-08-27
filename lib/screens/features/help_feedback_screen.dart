import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();

  String _selectedCategory = 'General Feedback';
  final List<String> _categories = [
    'General Feedback',
    'App Issue / Bug',
    'Song Library Request',
    'Worship Center Update',
    'Church Inquiry',
    'Report User / Content',
    'Other Concerns',
  ];

  bool _isSubmitting = false;
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoadingTickets = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _fetchTickets() async {
    final email = UserService.instance.value.email;
    if (email.isEmpty) return;

    try {
      final items = await FirestoreService().getUserHelpFeedbacks(email);
      if (mounted) {
        setState(() {
          _tickets = items;
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final email = UserService.instance.value.email;
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    final contact = _contactController.text.trim();

    try {
      await FirestoreService().submitHelpFeedback(
        category: _selectedCategory,
        subject: subject,
        message: message,
        submittedByEmail: email,
        contactNumber: contact,
      );

      _subjectController.clear();
      _messageController.clear();
      _contactController.clear();

      await _fetchTickets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your feedback request has been submitted successfully.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _tabController.animateTo(1); // Switch to My Tickets tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildFormTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner/Helper Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Have a question, feedback, or app issue? Write your request below, and our administrator or support team will address your concern.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Category *',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: _categories.map((cat) {
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

            // Subject Input
            Text(
              'Subject *',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'e.g. Cannot find local center coordinates',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact Number (Optional)
            Text(
              'Contact Number (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 0917 123 4567',
              ),
            ),
            const SizedBox(height: 16),

            // Message Body Input
            Text(
              'Message / Detailed Concern *',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageController,
              maxLines: 6,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your question or feedback in detail here...',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please describe your concern';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Request',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildTicketsTab(ThemeData theme, bool isDark) {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No requests submitted yet',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your submitted inquiries or feed issues will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final String category = ticket['category'] ?? '';
          final String subject = ticket['subject'] ?? '';
          final String message = ticket['message'] ?? '';
          final String status = ticket['status'] ?? 'pending';
          final String adminReply = ticket['adminReply'] ?? '';
          final Timestamp? timestampVal = ticket['timestamp'] as Timestamp?;
          final DateTime date = timestampVal?.toDate() ?? DateTime.now();

          MaterialColor statusColor = Colors.orange;
          String statusText = 'Pending Review';
          if (status == 'in-progress') {
            statusColor = Colors.blue;
            statusText = 'In Progress';
          } else if (status == 'resolved') {
            statusColor = Colors.green;
            statusText = 'Resolved';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Category, Status, Date)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    subject,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text('•', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                        Text(
                          _formatDate(date),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor.shade800,
                      ),
                    ),
                  ),
                ),

                // Concern Message
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),

                // Admin Reply (if exists)
                if (adminReply.isNotEmpty) ...[
                  Divider(color: theme.dividerColor, height: 1),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2B2C) : const Color(0xFFF2F4F7),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Support Team Response',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          adminReply,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
      appBar: AppBar(
        title: const Text('Help & Helpline Support'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.rate_review_rounded), text: 'Submit Request'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'My Helpline Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(theme, isDark),
          _buildTicketsTab(theme, isDark),
        ],
      ),
    );
  }
}
