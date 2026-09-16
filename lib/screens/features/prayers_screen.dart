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

  String _capitalizeTitle(String text) {
    if (text.trim().isEmpty) return 'Untitled Prayer';
    final words = text.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Capitalized Prayer Title
                                        Text(
                                          _capitalizeTitle(title),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (content.isNotEmpty) ...[
                                          const SizedBox(height: 4),

                                          // Content Preview (1 Maxline)
                                          Text(
                                            content
                                                .replaceAll(
                                                    RegExp(r'\s+'), ' ')
                                                .trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              fontSize: 13,
                                              color: theme.textTheme
                                                  .bodySmall?.color,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Trailing Chevron Icon
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.hintColor,
                                    size: 22,
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
