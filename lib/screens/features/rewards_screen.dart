import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../services/firestore_service.dart';
import '../../services/dev_coins_service.dart';
import '../../models/user_profile.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DevCoinsBreakdown _breakdown = const DevCoinsBreakdown();
  bool _isLoadingCoins = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCoins();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    final email = UserService.instance.value.email;
    if (email.isEmpty) {
      if (mounted) setState(() => _isLoadingCoins = false);
      return;
    }

    final data = await DevCoinsService.instance.calculateDevCoins(email);
    if (mounted) {
      setState(() {
        _breakdown = data;
        _isLoadingCoins = false;
      });
    }
  }

  void _showRedemptionDialog({
    required BuildContext context,
    required UserProfile profile,
    required int availableCoins,
    required int costCoins,
    required int rewardAmount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formKey = GlobalKey<FormState>();
    String selectedBank = 'GCash';
    final otherBankController = TextEditingController();
    final nameController = TextEditingController(
      text: [profile.firstName, profile.lastName].join(' ').trim().isNotEmpty
          ? [profile.firstName, profile.lastName].join(' ').trim()
          : profile.nickname,
    );
    final accountNumberController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Redeem ₱$rewardAmount E-Credit',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Costs $costCoins Dev Coins • Balance: $availableCoins Dev Coins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(color: theme.dividerColor, height: 1),
                      const SizedBox(height: 16),

                      // Online Bank / E-Wallet Selector
                      Text(
                        'Select Online Bank / E-Wallet',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedBank,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'GCash',
                            child: Text('GCash'),
                          ),
                          DropdownMenuItem(
                            value: 'Maya',
                            child: Text('Maya'),
                          ),
                          DropdownMenuItem(
                            value: 'GoTyme',
                            child: Text('GoTyme Bank'),
                          ),
                          DropdownMenuItem(
                            value: 'MariBank',
                            child: Text('MariBank (Shopee)'),
                          ),
                          DropdownMenuItem(
                            value: 'Others',
                            child: Text('Others (Specify Bank/Wallet)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedBank = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Custom Bank Name Field (If Others is selected)
                      if (selectedBank == 'Others') ...[
                        Text(
                          'Specify Bank / E-Wallet Name',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: otherBankController,
                          decoration: InputDecoration(
                            hintText: 'e.g. BDO, BPI, UnionBank, SeaBank',
                            prefixIcon: const Icon(Icons.business_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (selectedBank == 'Others' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please specify your bank name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Account Name Field
                      Text(
                        'Account Holder Full Name',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Juan Dela Cruz',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter registered account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Account / Phone Number Field
                      Text(
                        selectedBank == 'GCash' || selectedBank == 'Maya'
                            ? 'Mobile Number'
                            : 'Account Number',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: accountNumberController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: selectedBank == 'GCash' || selectedBank == 'Maya'
                              ? '09XXXXXXXXX (11 digits)'
                              : 'Enter account / phone number',
                          prefixIcon: Icon(
                            selectedBank == 'GCash' || selectedBank == 'Maya'
                                ? Icons.phone_android_rounded
                                : Icons.tag_rounded,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Please enter account or mobile number';
                          }
                          if ((selectedBank == 'GCash' || selectedBank == 'Maya') &&
                              !RegExp(r'^09\d{9}$').hasMatch(v)) {
                            return 'Enter a valid 11-digit mobile number (starts with 09)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Direct processing notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.12 : 0.06,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Direct Processing: Your request will be verified and sent directly to your registered bank account or mobile wallet.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : theme.colorScheme.primary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  if (availableCoins < costCoins) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Insufficient Dev Coins for this reward.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);

                                  try {
                                    await FirestoreService().submitRedemptionRequest(
                                      userEmail: profile.email,
                                      userNickname: profile.nickname,
                                      coins: costCoins,
                                      amount: rewardAmount,
                                      bankMethod: selectedBank,
                                      otherBankName:
                                          otherBankController.text.trim(),
                                      accountNumber:
                                          accountNumberController.text.trim(),
                                      accountName: nameController.text.trim(),
                                    );

                                    await _loadCoins();

                                    if (context.mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          content: Text(
                                            '🎉 Redemption request for ₱$rewardAmount via $selectedBank submitted!',
                                          ),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              theme.colorScheme.error,
                                          content: Text(
                                            'Failed to submit request: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Confirm Redemption ($costCoins Dev Coins)',
                                  style: const TextStyle(
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
              ),
            );
          },
        );
      },
    );
  }

  void _showRulesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.volunteer_activism_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dev Coins & Guidelines',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Earn Dev Coins by contributing to the app',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dev Coins are awarded as tokens of gratitude to honor members who contribute songs, center updates, and fellowship posts to build and maintain our church app.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : theme.colorScheme.primary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildRuleItem(
                    theme: theme,
                    icon: Icons.music_note_rounded,
                    title: '5 Dev Coins per Approved Worship Song',
                    subtitle:
                        'Awarded once submitted song lyrics and chords are verified and approved by the admin.',
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem(
                    theme: theme,
                    icon: Icons.place_rounded,
                    title: '5 Dev Coins per Approved Center Details',
                    subtitle:
                        'Awarded when verified new local church centers or GPS locator updates are approved.',
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem(
                    theme: theme,
                    icon: Icons.forum_rounded,
                    title: '1 Dev Coin per Community Post',
                    subtitle:
                        'Awarded for sharing uplifting fellowship thoughts, prayers, and announcements.',
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem(
                    theme: theme,
                    icon: Icons.report_problem_rounded,
                    title: '-1 Dev Coin Penalty for Spam or Reported Posts',
                    subtitle:
                        'To keep the platform clean and genuine, repetitive or reported posts will result in a deduction.',
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem(
                    theme: theme,
                    icon: Icons.speed_rounded,
                    title: 'Daily Earning Cap (Max 30 Dev Coins / Day)',
                    subtitle:
                        'Prevents spam and ensures balanced, honest participation across the community.',
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem(
                    theme: theme,
                    icon: Icons.lock_clock_rounded,
                    title: '₱150 E-Credit Tier is One-Time Only',
                    subtitle:
                        'The ₱150 reward tier (950 Dev Coins) can only be redeemed once per account as a special milestone bonus.',
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1F29)
                          : const Color(0xFFF0F1F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Disclaimer: Google is not a sponsor of or involved in this community contributor recognition program.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile>(
      valueListenable: UserService.instance,
      builder: (context, profile, _) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService().getUserRedemptionsStream(profile.email),
          builder: (context, snapshot) {
            final redemptionDocs = snapshot.data?.docs ?? [];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Rewards'),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    tooltip: 'Dev Coins Info & Rules',
                    onPressed: () => _showRulesBottomSheet(context),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.stars_rounded, size: 20),
                      text: 'Dev Coins & Rewards',
                    ),
                    Tab(
                      icon: const Icon(Icons.history_rounded, size: 20),
                      text: redemptionDocs.isEmpty
                          ? 'History'
                          : 'History (${redemptionDocs.length})',
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Catalog & Balance
                  RefreshIndicator(
                    onRefresh: _loadCoins,
                    child: _buildCatalogTab(
                      context: context,
                      theme: theme,
                      isDark: isDark,
                      profile: profile,
                    ),
                  ),

                  // Tab 2: Redemptions History
                  _buildHistoryTab(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    docs: redemptionDocs,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogTab({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required UserProfile profile,
  }) {
    final availableCoins = _breakdown.availableCoins;
    final totalEarnedCoins = _breakdown.totalEarnedCoins;
    final spentCoins = _breakdown.spentCoins;
    final targetTier = DevCoinsService.instance.getNextTargetTier(
      availableCoins,
      _breakdown.redeemedCoinsTiers,
    );
    final double progress = (availableCoins / targetTier.coins).clamp(
      0.0,
      1.0,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Glass Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                      ]
                    : [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.3 : 0.25,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.contributions} Contributions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _isLoadingCoins ? '...' : '$availableCoins',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DEV COINS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Lifetime: $totalEarnedCoins coins',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        if (spentCoins > 0)
                          Text(
                            'Redeemed: $spentCoins coins',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.amberAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      availableCoins >= targetTier.coins
                          ? '🎉 Ready to redeem ₱${targetTier.pesos} E-Credit!'
                          : 'Need ${targetTier.coins - availableCoins} more Dev Coins for ₱${targetTier.pesos}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Today's Earning: ${_breakdown.todayEarnedCoins} / ${DevCoinsService.dailyCoinsCap} Dev Coins",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Catalog Title
          Row(
            children: [
              Text(
                'Available E-Credits',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Direct Transfer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render Reward Tiers
          ...DevCoinsService.tiers.map((tier) {
            final bool isClaimed = _breakdown.isTierAlreadyClaimed(tier);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRewardCard(
                context: context,
                theme: theme,
                isDark: isDark,
                costCoins: tier.coins,
                amount: tier.pesos,
                description: tier.description,
                isOneTime: tier.isOneTime,
                isClaimed: isClaimed,
                userBalance: availableCoins,
                onRedeem: () => _showRedemptionDialog(
                  context: context,
                  profile: profile,
                  availableCoins: availableCoins,
                  costCoins: tier.coins,
                  rewardAmount: tier.pesos,
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Contributor Guidelines Tile
          InkWell(
            onTap: () => _showRulesBottomSheet(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1F29)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dev Coins Rules & Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          'How to earn, penalties & daily cap • Max 30 coins/day',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.textTheme.bodySmall?.color,
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
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required int costCoins,
    required int amount,
    required String description,
    required bool isOneTime,
    required bool isClaimed,
    required int userBalance,
    required VoidCallback onRedeem,
  }) {
    final bool canAfford = userBalance >= costCoins && !isClaimed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed
              ? theme.dividerColor.withValues(alpha: 0.35)
              : canAfford
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.dividerColor.withValues(alpha: 0.5),
          width: canAfford ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isClaimed
                      ? (isDark
                          ? const Color(0xFF24252C)
                          : const Color(0xFFEBECEF))
                      : canAfford
                          ? theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            )
                          : (isDark
                              ? const Color(0xFF2C2D35)
                              : const Color(0xFFF0F1F5)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isClaimed
                      ? Icons.check_circle_outline_rounded
                      : Icons.payments_rounded,
                  color: isClaimed
                      ? theme.hintColor
                      : canAfford
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Required Coins Pill / Label + One-Time Badge
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: isClaimed
                              ? theme.disabledColor
                              : theme.colorScheme.primary,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$costCoins Dev Coins',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isClaimed
                                ? theme.disabledColor
                                : theme.colorScheme.primary,
                          ),
                        ),
                        if (isOneTime) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isClaimed
                                  ? Colors.grey.withValues(alpha: 0.15)
                                  : Colors.amber.withValues(
                                      alpha: isDark ? 0.25 : 0.15,
                                    ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_clock_rounded,
                                  size: 11,
                                  color: isClaimed
                                      ? theme.hintColor
                                      : (isDark
                                          ? Colors.amberAccent
                                          : Colors.orange.shade800),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'One-Time Only',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isClaimed
                                        ? theme.hintColor
                                        : (isDark
                                            ? Colors.amberAccent
                                            : Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Amount
                    Text(
                      '₱$amount E-Credit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isClaimed ? theme.disabledColor : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Subtext
                    Text(
                      isClaimed
                          ? '✓ One-time reward already claimed'
                          : description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isClaimed
                            ? theme.disabledColor
                            : theme.textTheme.bodySmall?.color,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Redeem Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: canAfford ? onRedeem : null,
              style: FilledButton.styleFrom(
                backgroundColor: isClaimed
                    ? (isDark
                        ? const Color(0xFF24252C)
                        : const Color(0xFFEBECEF))
                    : canAfford
                        ? theme.colorScheme.primary
                        : (isDark
                            ? const Color(0xFF2C2D35)
                            : const Color(0xFFE4E6EB)),
                foregroundColor: canAfford ? Colors.white : theme.disabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isClaimed ? 'Already Claimed (1x Limit)' : 'Redeem',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required List<QueryDocumentSnapshot> docs,
    required bool isLoading,
  }) {
    if (isLoading && docs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Redemption Requests Yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Earn Dev Coins by contributing worship songs, center updates, and fellowship posts, then redeem them here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final int amount = (data['amount'] as num?)?.toInt() ?? 0;
        final int coins =
            (data['coins'] ?? data['points'] as num?)?.toInt() ?? 0;
        final String status =
            (data['status'] as String?)?.toLowerCase() ?? 'pending';
        final String bankMethod =
            data['bankMethod'] ?? data['rewardType'] ?? 'E-Credit';
        final String otherBankName = data['otherBankName'] ?? '';
        final String bankDisplay = bankMethod == 'Others' && otherBankName.isNotEmpty
            ? otherBankName
            : bankMethod;
        final String accountNumber = data['accountNumber'] ?? '';
        final String accountName = data['accountName'] ?? '';
        final String adminNote = data['adminNote'] ?? '';
        final Timestamp? timestamp = data['timestamp'] as Timestamp?;
        final dateStr = timestamp != null
            ? '${timestamp.toDate().month}/${timestamp.toDate().day}/${timestamp.toDate().year}'
            : 'Recent';

        Color statusColor;
        String statusLabel;
        IconData statusIcon;

        switch (status) {
          case 'completed':
          case 'approved':
            statusColor = Colors.green;
            statusLabel = 'Completed';
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'rejected':
            statusColor = Colors.red;
            statusLabel = 'Declined';
            statusIcon = Icons.cancel_rounded;
            break;
          case 'pending':
          default:
            statusColor = Colors.orange;
            statusLabel = 'Under Review';
            statusIcon = Icons.schedule_rounded;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₱$amount via $bankDisplay',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$coins Dev Coins • Requested on $dateStr',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'To: $accountName ($accountNumber)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (adminNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Note: $adminNote',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
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
    );
  }
}
