import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import 'history_model.dart';
import 'history_data.dart';
import 'history_styles.dart';
import 'history_detail_screen.dart';
import '../../services/ad_service.dart';

class UecfiHistoryScreen extends StatefulWidget {
  const UecfiHistoryScreen({super.key});

  @override
  State<UecfiHistoryScreen> createState() => _UecfiHistoryScreenState();
}

class _UecfiHistoryScreenState extends State<UecfiHistoryScreen> {
  TopicCategory _selectedCategory = TopicCategory.all;
  List<HistoryTopic> get _filteredTopics {
    if (_selectedCategory == TopicCategory.all) {
      return HistoryData.topics;
    }
    return HistoryData.topics
        .where((topic) => topic.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HistoryStyles.isDark(context);
    final textPrimary = HistoryStyles.textPrimary(context);
    final textSecondary = HistoryStyles.textSecondary(context);
    final subtleBg = HistoryStyles.subtleBackground(context);

    return Scaffold(
      backgroundColor: subtleBg,
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AdBannerWidget(),
      ),
      appBar: AppBar(
        title: const Text('UECFI Heritage & History'),
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
          // 1. Hero Header Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8A2387),
                    Color(0xFFE94057),
                    Color(0xFFF27121),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94057).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -25,
                    child: AppIcon(
                      icon: HugeIcons.strokeRoundedLegalDocument01,
                      size: 130,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              icon: HugeIcons.strokeRoundedSparkles,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'HERITAGE & TRUTH',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Discover Our Sacred Roots',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Explore the founding story, the brave pioneers of 1900, and the divine revelation of the Holy Spirit.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Category Filter Chips
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: TopicCategory.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = TopicCategory.values[index];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    showCheckmark: false,
                    avatar: AppIcon(
                      icon: cat.icon,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    label: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ),

          // 4. Topic Cards or Timeline View
          if (_selectedCategory == TopicCategory.timeline)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = HistoryData.timelineEvents[index];
                    final isLast =
                        index == HistoryData.timelineEvents.length - 1;
                    return _buildTimelineItem(
                      context,
                      event,
                      isLast,
                      textPrimary,
                      textSecondary,
                    );
                  },
                  childCount: HistoryData.timelineEvents.length,
                ),
              ),
            )
          else ...[
            // Story Cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: _filteredTopics.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            AppIcon(
                              icon: HugeIcons.strokeRoundedBookOpen01,
                              size: 48,
                              color: textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No stories found in this category',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final topic = _filteredTopics[index];
                          return _buildTopicCard(context, topic);
                        },
                        childCount: _filteredTopics.length,
                      ),
                    ),
            ),

            // Quick Peek Timeline Section when on "All"
            if (_selectedCategory == TopicCategory.all)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Historical Milestones',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = TopicCategory.timeline;
                              });
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...HistoryData.timelineEvents.take(4).map(
                            (ev) => _buildTimelineItem(
                              context,
                              ev,
                              false,
                              textPrimary,
                              textSecondary,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
          ],
          ],
        ),
      ),
    );
  }

  // --- STORY CARD WIDGET ---
  Widget _buildTopicCard(BuildContext context, HistoryTopic topic) {
    final isDark = HistoryStyles.isDark(context);
    final textPrimary = HistoryStyles.textPrimary(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: HistoryStyles.cardDecoration(
        context: context,
        gradientColors: topic.gradientColors,
        borderRadius: 22,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HistoryDetailScreen(topic: topic),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Pill, Read Time Pill & Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: topic.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            topic.category.label,
                            style: TextStyle(
                              color: topic.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: HistoryStyles.pillDecoration(
                            context: context,
                            color: topic.primaryColor,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(
                                icon: HugeIcons.strokeRoundedClock01,
                                size: 12,
                                color: topic.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${topic.readTimeMinutes} min',
                                style: TextStyle(
                                  color: topic.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Circle Icon Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: HistoryStyles.badgeDecoration(
                        gradientColors: topic.gradientColors,
                        radius: 14,
                      ),
                      child: AppIcon(
                        icon: topic.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title & Subtitle
                Text(
                  topic.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.subtitle,
                  style: TextStyle(
                    color: topic.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                // Snippet
                Text(
                  topic.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HistoryStyles.textSecondary(context),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 16),

                // Action Footprint: "Read Full Story" with Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Read story',
                      style: TextStyle(
                        color: topic.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : topic.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: topic.primaryColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TIMELINE STEPPER ITEM ---
  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEvent event,
    bool isLast,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isDark = HistoryStyles.isDark(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year Indicator Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 12),
                Text(
                  event.year,
                  style: TextStyle(
                    color: event.gradientColors.first,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Stepper Line & Dot
          Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: event.gradientColors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: event.gradientColors.first.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const AppIcon(
                  icon: HugeIcons.strokeRoundedTick01,
                  size: 11,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: event.gradientColors.first.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Event Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HistoryStyles.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: HistoryStyles.borderColor(context),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: event.gradientColors.first.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.badgeText,
                      style: TextStyle(
                        color: event.gradientColors.first,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
