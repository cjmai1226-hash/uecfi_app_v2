import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DevCoinsBreakdown {
  final int availableCoins;
  final int totalEarnedCoins;
  final int spentCoins;
  final int todayEarnedCoins;
  final Set<int> redeemedCoinsTiers;

  const DevCoinsBreakdown({
    this.availableCoins = 0,
    this.totalEarnedCoins = 0,
    this.spentCoins = 0,
    this.todayEarnedCoins = 0,
    this.redeemedCoinsTiers = const {},
  });

  bool isTierAlreadyClaimed(DevCoinsTier tier) {
    if (!tier.isOneTime) return false;
    return redeemedCoinsTiers.contains(tier.coins);
  }
}

class DevCoinsTier {
  final int coins;
  final int pesos;
  final String title;
  final String description;
  final bool isOneTime;

  const DevCoinsTier({
    required this.coins,
    required this.pesos,
    required this.title,
    required this.description,
    this.isOneTime = false,
  });
}

class DevCoinsService {
  static final DevCoinsService instance = DevCoinsService._internal();
  factory DevCoinsService() => instance;
  DevCoinsService._internal();

  static const int dailyCoinsCap = 30;

  static const List<DevCoinsTier> tiers = [
    DevCoinsTier(
      coins: 150,
      pesos: 20,
      title: '₱20 E-Credit',
      description: 'Instant online bank or e-wallet transfer',
      isOneTime: false,
    ),
    DevCoinsTier(
      coins: 350,
      pesos: 50,
      title: '₱50 E-Credit',
      description: 'Direct online bank or e-wallet transfer',
      isOneTime: false,
    ),
    DevCoinsTier(
      coins: 950,
      pesos: 150,
      title: '₱150 E-Credit',
      description: 'Special one-time bonus reward for dedicated contributors',
      isOneTime: true,
    ),
  ];

  DevCoinsTier getNextTargetTier(
    int currentCoins, [
    Set<int> claimedTiers = const {},
  ]) {
    for (final tier in tiers) {
      if (tier.isOneTime && claimedTiers.contains(tier.coins)) {
        continue;
      }
      if (currentCoins < tier.coins) {
        return tier;
      }
    }
    return tiers.firstWhere(
      (t) => !t.isOneTime || !claimedTiers.contains(t.coins),
      orElse: () => tiers.last,
    );
  }

  /// Calculates real-time Dev Coins from Firestore activities
  Future<DevCoinsBreakdown> calculateDevCoins(String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const DevCoinsBreakdown();
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final todayStr = _formatDateKey(DateTime.now());
      final Map<String, int> dailyPoints = {};

      // 1. Fetch User Community Posts (+1 for active, -1 for reported)
      final postSnap = await firestore
          .collection('community_posts')
          .where('authorEmail', isEqualTo: cleanEmail)
          .get();

      for (var doc in postSnap.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        final dateKey = _formatDateKey(date);

        final isReported = data['isReported'] == true;
        final delta = isReported ? -1 : 1;
        dailyPoints[dateKey] = (dailyPoints[dateKey] ?? 0) + delta;
      }

      // 2. Fetch User Song Submissions (+5 only if approved)
      final songSnap = await firestore
          .collection('song_submissions')
          .where('submittedBy', isEqualTo: cleanEmail)
          .get();

      for (var doc in songSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'pending').toString().toLowerCase();
        if (status == 'approved') {
          final timestamp = data['timestamp'] as Timestamp?;
          final date = timestamp?.toDate() ?? DateTime.now();
          final dateKey = _formatDateKey(date);
          dailyPoints[dateKey] = (dailyPoints[dateKey] ?? 0) + 5;
        }
      }

      // 3. Fetch User Center Updates (+5 only if approved)
      final centerSnap = await firestore
          .collection('center_updates')
          .where('submittedBy', isEqualTo: cleanEmail)
          .get();

      for (var doc in centerSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'pending').toString().toLowerCase();
        if (status == 'approved') {
          final timestamp = data['timestamp'] as Timestamp?;
          final date = timestamp?.toDate() ?? DateTime.now();
          final dateKey = _formatDateKey(date);
          dailyPoints[dateKey] = (dailyPoints[dateKey] ?? 0) + 5;
        }
      }

      // Sum daily capped points
      int lifetimeEarned = 0;
      int todayEarned = 0;

      for (var entry in dailyPoints.entries) {
        final int cappedDaily = entry.value.clamp(0, dailyCoinsCap).toInt();
        lifetimeEarned += cappedDaily;
        if (entry.key == todayStr) {
          todayEarned = cappedDaily;
        }
      }

      // 4. Calculate Redeemed / Spent Coins
      final redemptionsSnap = await firestore
          .collection('reward_redemptions')
          .where('userEmail', isEqualTo: cleanEmail)
          .get();

      int spentCoins = 0;
      final Set<int> redeemedCoinsTiers = {};
      for (var doc in redemptionsSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'pending').toString().toLowerCase();
        // Rejected redemptions refund the coins back
        if (status != 'rejected') {
          final dynamic rawCoins = data['coins'] ?? data['points'];
          final int pts = rawCoins is num
              ? rawCoins.toInt()
              : (int.tryParse(rawCoins?.toString() ?? '') ?? 0);
          spentCoins += pts;
          if (pts > 0) {
            redeemedCoinsTiers.add(pts);
          }
        }
      }

      final int availableCoins =
          (lifetimeEarned - spentCoins).clamp(0, 999999).toInt();

      return DevCoinsBreakdown(
        availableCoins: availableCoins,
        totalEarnedCoins: lifetimeEarned,
        spentCoins: spentCoins,
        todayEarnedCoins: todayEarned,
        redeemedCoinsTiers: redeemedCoinsTiers,
      );
    } catch (e) {
      debugPrint('Error calculating Dev Coins: $e');
      return const DevCoinsBreakdown();
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
