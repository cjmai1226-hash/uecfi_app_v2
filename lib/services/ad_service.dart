import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;
  AdService._internal();

  // ─── Production Ad Unit IDs ───────────────────────────────────────────────
  static const String _appOpenAdUnitId =
      'ca-app-pub-8333503696162383/8257320695';
  static const String _bannerAdUnitId =
      'ca-app-pub-8333503696162383/6101930646';
  static const String _interstitialAdUnitId =
      'ca-app-pub-8333503696162383/4788848973';
  static const String _rewardedAdUnitId =
      'ca-app-pub-8333503696162383/2814402267';

  // ─── Test Ad Unit IDs ─────────────────────────────────────────────────────
  static const String _testAppOpenAndroidId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIOSId =
      'ca-app-pub-3940256099942544/5532089241';

  static const String _testBannerAndroidId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOSId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialAndroidId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOSId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _testRewardedAndroidId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIOSId =
      'ca-app-pub-3940256099942544/1712485313';

  // ─── State ────────────────────────────────────────────────────────────────
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Action counter to throttle interstitial ads to only show every 3rd transition request.
  int _interstitialActionCount = 0;
  static const int _interstitialActionsRequired = 3;

  /// Timestamp of the last interstitial impression. Used to enforce the
  /// Google AdMob policy minimum gap between interstitials (~180 seconds).
  DateTime? _lastInterstitialShown;
  static const Duration _minInterstitialInterval = Duration(seconds: 180);

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ─── Initialisation ───────────────────────────────────────────────────────

  Future<void> initializeMobileAds() async {
    if (!isSupportedPlatform) return;
    await MobileAds.instance.initialize();
    debugPrint('AdMob: initialized');
    // Pre-load an interstitial immediately so it is ready for the first
    // natural transition.
    _loadInterstitialAd();
  }

  // ─── ID helpers ───────────────────────────────────────────────────────────

  String get _appOpenId => kDebugMode
      ? (Platform.isIOS ? _testAppOpenIOSId : _testAppOpenAndroidId)
      : _appOpenAdUnitId;

  String getBannerAdUnitId() => kDebugMode
      ? (Platform.isIOS ? _testBannerIOSId : _testBannerAndroidId)
      : _bannerAdUnitId;

  String get _interstitialId => kDebugMode
      ? (Platform.isIOS ? _testInterstitialIOSId : _testInterstitialAndroidId)
      : _interstitialAdUnitId;

  String get _rewardedId => kDebugMode
      ? (Platform.isIOS ? _testRewardedIOSId : _testRewardedAndroidId)
      : _rewardedAdUnitId;

  // ─── App Open Ad ──────────────────────────────────────────────────────────

  void loadAndShowAppOpenAd() {
    if (!isSupportedPlatform) return;
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob: AppOpen ad loaded');
          _appOpenAd = ad;
          _appOpenAd!.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob: AppOpen ad failed to load — $error');
        },
      ),
    );
  }

  // ─── Interstitial Ad ──────────────────────────────────────────────────────

  /// Pre-loads the next interstitial in the background so it is ready
  /// instantly for the next natural transition.
  void _loadInterstitialAd() {
    if (!isSupportedPlatform) return;
    if (_isInterstitialLoading) return; // prevent duplicate loads
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
          debugPrint('AdMob: Interstitial pre-loaded ✓');

          // Auto-reload once the ad is dismissed or fails to show so there
          // is always a fresh ad in the buffer.
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('AdMob: Interstitial shown');
              _lastInterstitialShown = DateTime.now();
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdMob: Interstitial dismissed — reloading');
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // Reload for the next opportunity
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdMob: Interstitial failed to show — $error');
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('AdMob: Interstitial failed to load — $error');
          // Retry after a delay to avoid hammering the network
          Future.delayed(const Duration(seconds: 60), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Shows the pre-loaded interstitial if:
  ///   • A loaded ad is available
  ///   • At least [_minInterstitialInterval] has elapsed since the last impression
  ///
  /// Call this at **natural screen transitions only** (e.g. opening a song
  /// detail, navigating a Bible chapter, or switching a main tab) to comply
  /// with Google AdMob policy.
  ///
  /// Returns `true` if an ad was shown.
  bool showInterstitialIfReady() {
    if (!isSupportedPlatform) return false;

    _interstitialActionCount++;
    if (_interstitialActionCount < _interstitialActionsRequired) {
      debugPrint(
        'AdMob: Interstitial request count $_interstitialActionCount/$_interstitialActionsRequired — skipping',
      );
      return false;
    }

    if (_interstitialAd == null) {
      debugPrint('AdMob: Interstitial not ready yet');
      return false;
    }

    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < _minInterstitialInterval) {
      debugPrint('AdMob: Interstitial cooldown active — skipping');
      return false;
    }

    _interstitialActionCount = 0; // Reset counter
    _interstitialAd!.show();
    _interstitialAd = null; // Will be replaced via fullScreenContentCallback
    return true;
  }

  // ─── Rewarded Ad ──────────────────────────────────────────────────────────

  Future<void> showDirectRewardedAd({
    required BuildContext context,
    required VoidCallback onReward,
  }) async {
    if (!isSupportedPlatform) {
      onReward();
      return;
    }
    _loadAndShowRewardedAd(context, onReward);
  }

  Future<void> showRewardedAdDialog({
    required BuildContext context,
    required VoidCallback onReward,
    String title = 'Support Us',
    String content = 'Watch a short ad to continue?',
  }) async {
    if (!isSupportedPlatform) {
      onReward();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _loadAndShowRewardedAd(context, onReward);
            },
            child: const Text(' Proceed '),
          ),
        ],
      ),
    );
  }

  void _loadAndShowRewardedAd(BuildContext context, VoidCallback onReward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          Navigator.pop(context);
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onReward();
            },
          );
        },
        onAdFailedToLoad: (error) {
          Navigator.pop(context);
          debugPrint('AdMob: Rewarded ad failed to load — $error');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load ad. Proceeding...')),
          );
          onReward();
        },
      ),
    );
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  void dispose() {
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
  }
}

// ─── Banner Ad Widget ─────────────────────────────────────────────────────────

class AdBannerWidget extends StatefulWidget {
  final double height;
  const AdBannerWidget({super.key, this.height = 50.0});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    if (AdService().isSupportedPlatform) {
      _createBannerAd();
    }
  }

  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService().getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob: Banner failed to load — $error');
          ad.dispose();
          if (mounted) {
            setState(() => _isAdLoaded = false);
          }
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    if (AdService().isSupportedPlatform) {
      _bannerAd.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService().isSupportedPlatform || !_isAdLoaded || _isClosed) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: GestureDetector(
                onTap: () => setState(() => _isClosed = true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
