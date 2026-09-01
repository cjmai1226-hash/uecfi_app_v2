import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/bylaw_model.dart';
import '../details/bylaw_detail_screen.dart';
import '../../services/ad_service.dart';

class BylawsScreen extends StatefulWidget {
  const BylawsScreen({super.key});

  @override
  State<BylawsScreen> createState() => _BylawsScreenState();
}

class _BylawsScreenState extends State<BylawsScreen> {
  List<BylawModel> _bylaws = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBylawsData();
  }

  Future<void> _loadBylawsData() async {
    try {
      final bylaws = await DatabaseHelper.getAllBylaws();
      setState(() {
        _bylaws = bylaws;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

    return Scaffold(
      bottomNavigationBar: const AdBannerWidget(),
      appBar: AppBar(
        title: const Text('Church Bylaws'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bylaws.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Bylaws Found',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bylaws.length,
                  itemBuilder: (context, index) {
                    final bylaw = _bylaws[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BylawDetailScreen(
                                bylaws: _bylaws,
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      bylaw.title.isNotEmpty ? bylaw.title : 'Untitled Article',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (bylaw.chapters != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'CH.${bylaw.chapters}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Content Preview
                              Text(
                                _getContentPreview(bylaw.content),
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
  }
}
