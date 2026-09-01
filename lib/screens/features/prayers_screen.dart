import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/prayer_language_service.dart';
import '../../models/prayer_model.dart';
import '../details/prayer_detail_screen.dart';
import '../../services/ad_service.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  List<PrayerModel> _prayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayersData();
  }

  Future<void> _loadPrayersData() async {
    try {
      final prayers = await DatabaseHelper.getAllPrayers();
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Truncate long content string for preview display
  String _getContentPreview(String content) {
    if (content.trim().isEmpty) return 'No preview available.';
    final cleanText = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanText.length <= 100) return cleanText;
    return '${cleanText.substring(0, 100)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: PrayerLanguageService.instance,
      builder: (context, langCode, child) {
        return Scaffold(
          bottomNavigationBar: const AdBannerWidget(),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _prayers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.import_contacts_outlined,
                            size: 48,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Prayers Found',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _prayers.length,
                      itemBuilder: (context, index) {
                        final prayer = _prayers[index];
                        final title = prayer.getDisplayTitle(langCode);
                        final content = prayer.getDisplayContent(langCode);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PrayerDetailScreen(
                                    prayers: _prayers,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isNotEmpty ? title : 'Untitled Prayer',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Content Preview
                                  Text(
                                    _getContentPreview(content),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
