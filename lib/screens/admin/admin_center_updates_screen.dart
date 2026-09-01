import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class AdminCenterUpdatesScreen extends StatefulWidget {
  const AdminCenterUpdatesScreen({super.key});

  @override
  State<AdminCenterUpdatesScreen> createState() =>
      _AdminCenterUpdatesScreenState();
}

class _AdminCenterUpdatesScreenState extends State<AdminCenterUpdatesScreen> {
  List<Map<String, dynamic>> _updates = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final updates = await FirestoreService().getAllCenterUpdates();
      if (mounted) {
        setState(() {
          _updates = updates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown date';
  }

  void _showReviewBottomSheet(Map<String, dynamic> update) {
    String selectedStatus = update['status'] ?? 'pending';
    final notesController = TextEditingController(
      text: update['adminNotes'] ?? '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final payload =
                update['payload'] as Map<String, dynamic>? ?? {};
            final status = selectedStatus;
            final statusColor = _getStatusColor(status);
            final updateType =
                update['updateType'] ?? 'Location Locator';
            final existingAdminNotes =
                update['adminNotes'] as String? ?? '';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Top Drag Handle Pill
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Review Center Update',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: theme.dividerColor, height: 1),

                      // Sheet Body
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Center Name & Status Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        update['centerName'] ?? 'Worship Center',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if ((update['centerAddress'] ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          update['centerAddress'],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme
                                                .textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: statusColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Type Tag
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTypeIcon(updateType),
                                      size: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Type: $updateType',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Submitter info & timestamp
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'By: ${update['submittedBy'] ?? 'Anonymous'}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(update['timestamp']),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Proposed Information Card
                            Text(
                              'Proposed Information',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (payload.containsKey('latLng') &&
                                        (payload['latLng'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'Coordinates:',
                                        payload['latLng'],
                                      ),
                                    if (payload.containsKey('mapsLink') &&
                                        (payload['mapsLink'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'Maps Link:',
                                        payload['mapsLink'],
                                      ),
                                    if (payload.containsKey('contactName') &&
                                        (payload['contactName'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'Contact Name:',
                                        payload['contactName'],
                                      ),
                                    if (payload.containsKey('contactRole') &&
                                        (payload['contactRole'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'Role / Position:',
                                        payload['contactRole'],
                                      ),
                                    if (payload.containsKey('contactNumber') &&
                                        (payload['contactNumber'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'Phone Number:',
                                        payload['contactNumber'],
                                      ),
                                    if (payload.containsKey('facebookPage') &&
                                        (payload['facebookPage'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'Facebook URL:',
                                        payload['facebookPage'],
                                      ),
                                    if (payload.containsKey('historyText') &&
                                        (payload['historyText'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'History Text:',
                                        payload['historyText'],
                                      ),
                                    if (payload.containsKey('notes') &&
                                        (payload['notes'] as String).isNotEmpty)
                                      _buildInfoRow(
                                        'User Remarks:',
                                        payload['notes'],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Admin Notes (if exists)
                            if (existingAdminNotes.isNotEmpty) ...[
                              Text(
                                'Previous Admin Note',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  existingAdminNotes,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Update Status
                            Text(
                              'Update Status',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedStatus,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pending Review'),
                                ),
                                DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Approve Update'),
                                ),
                                DropdownMenuItem(
                                  value: 'rejected',
                                  child: Text('Reject Update'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    selectedStatus = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Admin Notes / Remarks
                            Text(
                              'Admin Notes / Remarks',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Internal remarks or notes...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Save Status Action Button (Full width)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setSheetState(() {
                                          isSaving = true;
                                        });
                                        try {
                                          await FirestoreService()
                                              .respondToCenterUpdate(
                                            updateId: update['id'],
                                            status: selectedStatus,
                                            adminNotes: notesController
                                                .text
                                                .trim(),
                                          );
                                          if (context.mounted) {
                                            Navigator.of(sheetContext).pop();
                                            _loadUpdates();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Center update status saved!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setSheetState(() {
                                            isSaving = false;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error saving status: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.amber.shade800;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Location Locator':
        return Icons.place_rounded;
      case 'Contact Person':
        return Icons.person_rounded;
      case 'Facebook Page':
        return Icons.facebook;
      case 'Center History':
        return Icons.history_edu_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredUpdates = _updates.where((u) {
      if (_selectedFilter == 'all') return true;
      return (u['status'] ?? 'pending').toString().toLowerCase() ==
          _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Center Updates'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadUpdates,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All (${_updates.length})', 'all', theme),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Pending (${_updates.where((u) => (u['status'] ?? 'pending') == 'pending').length})',
                  'pending',
                  theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Approved (${_updates.where((u) => u['status'] == 'approved').length})',
                  'approved',
                  theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Rejected (${_updates.where((u) => u['status'] == 'rejected').length})',
                  'rejected',
                  theme,
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text('Error loading updates: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUpdates,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredUpdates.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No ${_selectedFilter == "all" ? "" : "$_selectedFilter "}center updates found.',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUpdates,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredUpdates.length,
                              itemBuilder: (context, index) {
                                final update = filteredUpdates[index];
                                final status = update['status'] ?? 'pending';
                                final statusColor = _getStatusColor(status);
                                final updateType =
                                    update['updateType'] ?? 'Location Locator';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: theme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        _showReviewBottomSheet(update),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Row 1: Center Name, Address & Status Badge
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      update['centerName'] ??
                                                          'Worship Center',
                                                      style: theme
                                                          .textTheme.titleMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    if ((update['centerAddress'] ??
                                                            '')
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        update['centerAddress'],
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: statusColor,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Row 2: Update Type Pill & Tap Chevron
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _getTypeIcon(updateType),
                                                      size: 13,
                                                      color: theme
                                                          .colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      updateType,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                color: theme.hintColor,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey, ThemeData theme) {
    final isSelected = _selectedFilter == filterKey;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filterKey;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFE4E6EB)
                        : const Color(0xFF050505)),
            ),
          ),
        ),
      ),
    );
  }
}
