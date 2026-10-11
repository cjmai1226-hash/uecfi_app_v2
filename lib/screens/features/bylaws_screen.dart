import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
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
                      AppIcon(
                        icon: HugeIcons.strokeRoundedLegalDocument01,
                        size: 44,
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
                                bylaw: bylaw,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bylaw Title
                              Text.rich(
                                TextSpan(
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '| ',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    TextSpan(
                                      text: bylaw.title.isNotEmpty
                                          ? bylaw.title
                                          : 'Untitled Article',
                                    ),
                                  ],
                                ),
                              ),
                              if (bylaw.content.isNotEmpty) ...[
                                const SizedBox(height: 4),

                                // Article Snippet (2 Maxlines)
                                Text(
                                  bylaw.content
                                      .replaceAll(RegExp(r'\s+'), ' ')
                                      .trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
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
