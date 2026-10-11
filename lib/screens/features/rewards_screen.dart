import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../services/firestore_service.dart';
import '../../services/dev_coins_service.dart';
import '../../models/user_profile.dart';

class RewardsScreen extends StatefulWidget {
  final bool showAppBar;
  const RewardsScreen({super.key, this.showAppBar = false});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  DevCoinsBreakdown _breakdown = const DevCoinsBreakdown();
  bool _isLoadingCoins = true;

  @override
  void initState() {
    super.initState();
    _loadCoins();
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

    final bankOptions = [
      {
        'id': 'GCash',
        'label': 'GCash',
        'icon': HugeIcons.strokeRoundedWallet01,
      },
      {
        'id': 'Maya',
        'label': 'Maya',
        'icon': HugeIcons.strokeRoundedCreditCard,
      },
      {
        'id': 'GoTyme',
        'label': 'GoTyme',
        'icon': HugeIcons.strokeRoundedPiggyBank,
      },
      {
        'id': 'MariBank',
        'label': 'MariBank',
        'icon': HugeIcons.strokeRoundedStore01,
      },
      {
        'id': 'Others',
        'label': 'Other Bank',
        'icon': HugeIcons.strokeRoundedBank,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final remainingAfter = availableCoins - costCoins;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Google M3 Drag Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Google Pay Style Modal Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: AppIcon(
                              icon: HugeIcons.strokeRoundedCoins01,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Redeem ₱$rewardAmount E-Credit',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Google Pay • Instant Contributor Payout',
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
                      const SizedBox(height: 20),

                      // Cost Summary Card (Google Receipt Card)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2128)
                              : const Color(0xFFF1F4F9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dev Coins cost',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                Row(
                                  children: [
                                    AppIcon(
                                      icon: HugeIcons.strokeRoundedAward01,
                                      size: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$costCoins coins',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Current balance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                Text(
                                  '$availableCoins coins',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Remaining balance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$remainingAfter coins',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: remainingAfter < 0
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bank / Wallet Selector - Google M3 Filter Chips
                      Text(
                        'Payout Destination',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: bankOptions.map((opt) {
                          final isSelected = selectedBank == opt['id'];
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  icon: opt['icon'] as List<List<dynamic>>,
                                  size: 16,
                                  color: isSelected
                                      ? (isDark
                                            ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                            : theme.colorScheme.onPrimary)
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(width: 6),
                                Text(opt['label'] as String),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: isDark
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                        ? theme.colorScheme.onPrimaryContainer
                                        : Colors.white)
                                  : theme.textTheme.bodyMedium?.color,
                              fontSize: 12.5,
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF1E2128)
                                : const Color(0xFFF1F4F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : theme.dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(
                                  () => selectedBank = opt['id'] as String,
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Custom Bank Name Field (If Others is selected)
                      if (selectedBank == 'Others') ...[
                        Text(
                          'Bank / E-Wallet Name',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: otherBankController,
                          decoration: InputDecoration(
                            hintText: 'e.g. BDO, BPI, UnionBank, SeaBank',
                            prefixIcon: const AppIcon(
                              icon: HugeIcons.strokeRoundedBank,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E2128)
                                : const Color(0xFFF8F9FC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
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
                        const SizedBox(height: 16),
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
                          prefixIcon: const AppIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E2128)
                              : const Color(0xFFF8F9FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter registered account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

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
                          hintText:
                              selectedBank == 'GCash' || selectedBank == 'Maya'
                              ? '09XXXXXXXXX (11 digits)'
                              : 'Enter account / phone number',
                          prefixIcon: AppIcon(
                            icon:
                                selectedBank == 'GCash' ||
                                    selectedBank == 'Maya'
                                ? HugeIcons.strokeRoundedSmartPhone01
                                : HugeIcons.strokeRoundedTag01,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E2128)
                              : const Color(0xFFF8F9FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Please enter account or mobile number';
                          }
                          if ((selectedBank == 'GCash' ||
                                  selectedBank == 'Maya') &&
                              !RegExp(r'^09\d{9}$').hasMatch(v)) {
                            return 'Enter a valid 11-digit mobile number (starts with 09)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Direct processing notice - Google Help Banner style
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.14 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppIcon(
                              icon: HugeIcons.strokeRoundedShieldCheck,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Verified Transfer: Your reward will be reviewed by church admin and disbursed directly to your chosen account.',
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
                      const SizedBox(height: 24),

                      // Google Style Stadium Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                                    await FirestoreService()
                                        .submitRedemptionRequest(
                                          userEmail: profile.email,
                                          userNickname: profile.nickname,
                                          coins: costCoins,
                                          amount: rewardAmount,
                                          bankMethod: selectedBank,
                                          otherBankName: otherBankController
                                              .text
                                              .trim(),
                                          accountNumber: accountNumberController
                                              .text
                                              .trim(),
                                          accountName: nameController.text
                                              .trim(),
                                        );

                                    await _loadCoins();

                                    if (context.mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
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
                                  'Confirm ₱$rewardAmount Transfer',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: AppIcon(
                            icon: HugeIcons.strokeRoundedAward01,
                            color: Color(0xFF1A73E8),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dev Coins Guidelines',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                            ),
                            Text(
                              'Earn rewards by contributing to the community',
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

                  // Intro Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2128)
                          : const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Color(0xFFEA4335),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dev Coins are tokens of appreciation honoring community members who add songs, update local church centers, and share fellowship in our app.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF3C4043),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Ways to Earn',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Google-styled colorful list items
                  _buildGoogleRuleCard(
                    theme: theme,
                    isDark: isDark,
                    icon: HugeIcons.strokeRoundedMusic02,
                    iconBgColor: const Color(0xFF1A73E8), // Google Blue
                    title: '5 Dev Coins per Approved Worship Song',
                    subtitle:
                        'Awarded once submitted chords and lyrics are verified by the admin team.',
                  ),
                  const SizedBox(height: 10),

                  _buildGoogleRuleCard(
                    theme: theme,
                    isDark: isDark,
                    icon: HugeIcons.strokeRoundedChurch,
                    iconBgColor: const Color(0xFF34A853), // Google Green
                    title: '5 Dev Coins per Approved Center Update',
                    subtitle:
                        'Awarded when new local center locations or GPS pin corrections are approved.',
                  ),
                  const SizedBox(height: 10),

                  _buildGoogleRuleCard(
                    theme: theme,
                    isDark: isDark,
                    icon: HugeIcons.strokeRoundedComment01,
                    iconBgColor: const Color(0xFF673AB7), // Material Purple
                    title: '1 Dev Coin per Community Post',
                    subtitle:
                        'Awarded for sharing uplifting devotionals, prayer requests, and testimonies.',
                  ),
                  const SizedBox(height: 10),

                  _buildGoogleRuleCard(
                    theme: theme,
                    isDark: isDark,
                    icon: HugeIcons.strokeRoundedDashboardSpeed01,
                    iconBgColor: const Color(0xFFFBBC04), // Google Amber
                    title: 'Daily Earning Cap (Max 30 Dev Coins / Day)',
                    subtitle:
                        'Ensures fair participation and keeps the contributor leaderboard balanced.',
                  ),
                  const SizedBox(height: 10),

                  _buildGoogleRuleCard(
                    theme: theme,
                    isDark: isDark,
                    icon: HugeIcons.strokeRoundedAlert02,
                    iconBgColor: const Color(0xFFEA4335), // Google Red
                    title: '-1 Dev Coin Penalty for Spam or Abuse',
                    subtitle:
                        'Repetitive, irrelevant, or community-reported posts will be penalized.',
                  ),
                  const SizedBox(height: 10),

                  _buildGoogleRuleCard(
                    theme: theme,
                    isDark: isDark,
                    icon: HugeIcons.strokeRoundedAward01,
                    iconBgColor: const Color(0xFF0097A7), // Cyan/Teal
                    title: '₱200 E-Credit Milestone Tier is One-Time',
                    subtitle:
                        'The ₱200 reward (950 Dev Coins) is an exclusive milestone reward claimable once per account.',
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2128)
                          : const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Disclaimer: Google is not a sponsor of or involved in this contributor recognition program.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Got it',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildGoogleRuleCard({
    required ThemeData theme,
    required bool isDark,
    required List<List<dynamic>> icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AppIcon(icon: icon, size: 20, color: iconBgColor),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.textTheme.bodySmall?.color,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            final isLoadingHistory =
                snapshot.connectionState == ConnectionState.waiting;

            return Scaffold(
              appBar: widget.showAppBar
                  ? AppBar(
                      title: const Text(
                        'Rewards',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      elevation: 0,
                      centerTitle: false,
                      actions: [
                        IconButton(
                          icon: const AppIcon(
                            icon: HugeIcons.strokeRoundedHelpCircle,
                            size: 22,
                          ),
                          tooltip: 'Dev Coins Info & Rules',
                          onPressed: () => _showRulesBottomSheet(context),
                        ),
                      ],
                    )
                  : null,
              body: RefreshIndicator(
                onRefresh: _loadCoins,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: _buildBody(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    profile: profile,
                    redemptionDocs: redemptionDocs,
                    isLoadingHistory: isLoadingHistory,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required UserProfile profile,
    required List<QueryDocumentSnapshot> redemptionDocs,
    required bool isLoadingHistory,
  }) {
    final availableCoins = _breakdown.availableCoins;
    final totalEarnedCoins = _breakdown.totalEarnedCoins;
    final spentCoins = _breakdown.spentCoins;
    final todayEarned = _breakdown.todayEarnedCoins;
    final dailyCap = DevCoinsService.dailyCoinsCap;
    final dailyProgress = (todayEarned / dailyCap).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==========================================
        // 1. Dev Coins Balance Master Gift Card
        // ==========================================
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(
                alpha: isDark ? 0.45 : 0.35,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.32 : 0.22,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Column(
              children: [
                // ==========================================
                // Card Face Artwork
                // ==========================================
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.85,
                                  ),
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.60,
                                  ),
                                  const Color(0xFF1A1C28),
                                ]
                              : [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.90,
                                  ),
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.78,
                                  ),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header Row: Logo & Contributor Pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcon(
                                      icon: HugeIcons.strokeRoundedGift,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'DEV COINS CARD',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.3,
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkBadge01,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${profile.contributions} Contrib.',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Large Balance Value
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _isLoadingCoins ? '...' : '$availableCoins',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.0,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'DEV COINS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Lifetime & Redeemed Badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Lifetime: $totalEarnedCoins coins',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              if (spentCoins > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Redeemed: $spentCoins coins',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Member Name & Wallet Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                profile.nickname.isNotEmpty
                                    ? profile.nickname.toUpperCase()
                                    : 'COMMUNITY MEMBER',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              Text(
                                'COMMUNITY WALLET',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Decorative Background Glow / Watermark Orbs
                    Positioned(
                      top: -25,
                      right: -15,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: 60,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 12,
                      child: AppIcon(
                        icon: HugeIcons.strokeRoundedAward01,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // Voucher Perforation & Ticket Notches
                // ==========================================
                Container(
                  color: isDark ? const Color(0xFF1E2128) : Colors.white,
                  child: SizedBox(
                    height: 18,
                    child: Row(
                      children: [
                        // Left ticket notch punching into scaffold background
                        Container(
                          width: 10,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(9),
                              bottomRight: Radius.circular(9),
                            ),
                          ),
                        ),
                        // Dashed perforation line
                        Expanded(
                          child: CustomPaint(
                            size: const Size(double.infinity, 2),
                            painter: _DashedLinePainter(
                              color: theme.dividerColor.withValues(
                                alpha: isDark ? 0.35 : 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Right ticket notch punching into scaffold background
                        Container(
                          width: 10,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(9),
                              bottomLeft: Radius.circular(9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // Voucher Stub (Daily Progress)
                // ==========================================
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2128) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(22),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              AppIcon(
                                icon: HugeIcons.strokeRoundedFlash,
                                size: 16,
                                color: isDark
                                    ? Colors.amberAccent
                                    : Colors.orange.shade800,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Today's Earning",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "$todayEarned / $dailyCap coins",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: dailyProgress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white12
                              : const Color(0xFFE4E7EC),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick Guidelines Chip / Tile (Google Help tile)
        InkWell(
          onTap: () => _showRulesBottomSheet(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2128) : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1A73E8,
                    ).withValues(alpha: isDark ? 0.25 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const AppIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: Color(0xFF1A73E8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to earn Dev Coins',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        'Up to 30 coins/day • Worship songs, center updates & posts',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: theme.hintColor,
                  size: 14,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ==========================================
        // 2. DevShop Section
        // ==========================================
        Row(
          children: [
            Text(
              'DevShop',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.22 : 0.12,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  AppIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'E-Credit Store',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Render 3-Column Reward Tiers
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < DevCoinsService.tiers.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildRewardCard(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    costCoins: DevCoinsService.tiers[i].coins,
                    amount: DevCoinsService.tiers[i].pesos,
                    isOneTime: DevCoinsService.tiers[i].isOneTime,
                    isClaimed: _breakdown.isTierAlreadyClaimed(
                      DevCoinsService.tiers[i],
                    ),
                    userBalance: availableCoins,
                    onRedeem: () => _showRedemptionDialog(
                      context: context,
                      profile: profile,
                      availableCoins: availableCoins,
                      costCoins: DevCoinsService.tiers[i].coins,
                      rewardAmount: DevCoinsService.tiers[i].pesos,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ==========================================
        // 3. Redemption History (Google Pay Activity style)
        // ==========================================
        Row(
          children: [
            Text(
              'Activity & History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            if (redemptionDocs.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${redemptionDocs.length}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // History Content
        if (isLoadingHistory && redemptionDocs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (redemptionDocs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2128) : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    icon: HugeIcons.strokeRoundedInvoice01,
                    size: 32,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Redemption Activity Yet',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When you redeem Dev Coins for E-Credits, transfer details and status will be tracked here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        else
          ...redemptionDocs.map(
            (doc) => _buildHistoryCard(theme: theme, isDark: isDark, doc: doc),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ==========================================
  // DevShop E-Credit Card (3-Column Layout)
  // ==========================================
  Widget _buildRewardCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required int costCoins,
    required int amount,
    required bool isOneTime,
    required bool isClaimed,
    required int userBalance,
    required VoidCallback onRedeem,
  }) {
    final bool canAfford = userBalance >= costCoins && !isClaimed;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed
              ? theme.dividerColor.withValues(alpha: 0.15)
              : canAfford
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : theme.dividerColor.withValues(alpha: 0.35),
          width: canAfford ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              if (isOneTime)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE37400).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '1X BONUS',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE37400),
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else
                const SizedBox(height: 19),
              Text(
                '₱$amount',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isClaimed
                      ? theme.disabledColor
                      : theme.textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'e-cred',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isClaimed
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton(
              onPressed: () {
                if (isClaimed) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          AppIcon(
                            icon: HugeIcons.strokeRoundedAlert02,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This milestone reward has already been claimed.',
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                  return;
                }

                if (!canAfford) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          AppIcon(
                            icon: HugeIcons.strokeRoundedCoins01,
                            size: 18,
                            color: Colors.amberAccent,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text('Not enough Dev Coins!')),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: isDark
                          ? const Color(0xFF2C2D35)
                          : const Color(0xFF1E2128),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                onRedeem();
              },
              style: FilledButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: canAfford
                    ? theme.colorScheme.primary
                    : (isDark
                          ? const Color(0xFF282A33)
                          : const Color(0xFFE9ECF0)),
                foregroundColor: canAfford
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon: isClaimed
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedCoins01,
                      size: 13,
                      color: isClaimed
                          ? theme.disabledColor
                          : (canAfford
                                ? Colors.white
                                : const Color(0xFFF9AB00)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isClaimed ? 'Claimed' : '$costCoins Coins',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isClaimed
                            ? theme.disabledColor
                            : (canAfford ? Colors.white : null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Google Pay Activity History Card
  // ==========================================
  Widget _buildHistoryCard({
    required ThemeData theme,
    required bool isDark,
    required QueryDocumentSnapshot doc,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final int amount = (data['amount'] as num?)?.toInt() ?? 0;
    final int coins = (data['coins'] ?? data['points'] as num?)?.toInt() ?? 0;
    final String status =
        (data['status'] as String?)?.toLowerCase() ?? 'pending';
    final String bankMethod =
        data['bankMethod'] ?? data['rewardType'] ?? 'E-Credit';
    final String otherBankName = data['otherBankName'] ?? '';
    final String bankDisplay =
        bankMethod == 'Others' && otherBankName.isNotEmpty
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
    List<List<dynamic>> statusIcon;

    switch (status) {
      case 'completed':
      case 'approved':
        statusColor = const Color(0xFF1E8E3E); // Google Green
        statusLabel = 'Completed';
        statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
        break;
      case 'rejected':
        statusColor = const Color(0xFFD93025); // Google Red
        statusLabel = 'Declined';
        statusIcon = HugeIcons.strokeRoundedCancel01;
        break;
      case 'pending':
      default:
        statusColor = const Color(0xFFF9AB00); // Google Amber
        statusLabel = 'In Review';
        statusIcon = HugeIcons.strokeRoundedClock01;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Circular status icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(
                    icon: statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₱$amount E-Credit',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bankDisplay • $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: Coins badge & status pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-$coins coins',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: theme.dividerColor.withValues(alpha: 0.4), height: 1),
          const SizedBox(height: 8),

          // Recipient line
          Row(
            children: [
              AppIcon(
                icon: HugeIcons.strokeRoundedUser,
                size: 14,
                color: theme.hintColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'To: $accountName • $accountNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Admin note if present
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  AppIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 14,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Admin: $adminNote',
                      style: TextStyle(
                        fontSize: 11.5,
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
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
