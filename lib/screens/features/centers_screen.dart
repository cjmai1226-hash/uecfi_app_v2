import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../services/database_helper.dart';
import '../../models/center_model.dart';
import '../details/center_detail_screen.dart';

class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key});

  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  List<CenterModel> _centers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCentersData();
  }

  Future<void> _loadCentersData() async {
    try {
      final centers = await DatabaseHelper.getAllCenters();
      // Sort naturally by District (District 1, District 2 ... District 19), then by Center Name
      centers.sort((a, b) {
        final distComp = DatabaseHelper.compareNatural(a.district, b.district);
        if (distComp != 0) return distComp;
        return a.name.compareTo(b.name);
      });
      setState(() {
        _centers = centers;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_centers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            icon: HugeIcons.strokeRoundedChurch,
                            size: 44,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Worship Centers Found',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final center = _centers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CenterDetailScreen(center: center),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Center Name Title
                                  Text.rich(
                                    TextSpan(
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                          text: center.name,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final locationParts = [
                                        if (center.district.isNotEmpty)
                                          center.district,
                                        if (center.area.isNotEmpty)
                                          center.area.startsWith('Area')
                                              ? center.area
                                              : 'Area ${center.area}',
                                        if (center.address.isNotEmpty)
                                          center.address
                                              .replaceAll(
                                                RegExp(r'\s+'),
                                                ' ',
                                              )
                                              .trim(),
                                      ];
                                      if (locationParts.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                        ),
                                        child: Text(
                                          locationParts.join(' • '),
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 13,
                                                color: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: _centers.length),
                    ),
                  ),
              ],
            ),
    );
  }
}
