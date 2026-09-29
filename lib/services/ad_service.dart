// lib/services/ad_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:google_fonts/google_fonts.dart';
import 'game_storage.dart';

class AdService {
  static bool _initialized = false;
  static int _levelsSinceLastInterstitial = 0;

  // ── Official Google AdMob Test Ad Unit IDs ─────────────────────────────────
  // Android test IDs
  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  // iOS test IDs
  static const String _iosBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  static String get bannerAdUnitId {
    if (kIsWeb) return _androidBannerId;
    return Platform.isAndroid ? _androidBannerId : _iosBannerId;
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return _androidInterstitialId;
    return Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return _androidRewardedId;
    return Platform.isAndroid ? _androidRewardedId : _iosRewardedId;
  }

  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;
    if (isMobilePlatform) {
      try {
        await MobileAds.instance.initialize();
        _initialized = true;
      } catch (e) {
        debugPrint('AdMob initialization notice: $e');
      }
    }
  }

  // ── Interstitial Ad (Level Completion) ────────────────────────────────────

  static void onLevelCompleted(BuildContext context) {
    if (GameStorage.isAdsRemoved()) return;

    _levelsSinceLastInterstitial++;
    // Highest impression & retention balance: show interstitial every 2 levels
    if (_levelsSinceLastInterstitial >= 2) {
      _levelsSinceLastInterstitial = 0;
      showInterstitial(context);
    }
  }

  static void showInterstitial(BuildContext context) {
    if (GameStorage.isAdsRemoved()) return;

    if (!isMobilePlatform || !_initialized) {
      _showSimulatedInterstitial(context);
      return;
    }

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, err) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed to load: $err');
          _showSimulatedInterstitial(context);
        },
      ),
    );
  }

  // ── Rewarded Ad: Extra Life ────────────────────────────────────────────────

  static void showRewardedLifeAd(
    BuildContext context, {
    required VoidCallback onRewardEarned,
  }) {
    // Note: Life refill always requires watching a rewarded ad even in premium
    if (!isMobilePlatform || !_initialized) {
      _showSimulatedRewardDialog(
        context,
        title: 'Revive Penguins',
        rewardText: '+3 Full Lives',
        icon: Icons.favorite_rounded,
        accentColor: const Color(0xFFE91E63),
        onRewardEarned: onRewardEarned,
      );
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (adWithoutView, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (err) {
          _showSimulatedRewardDialog(
            context,
            title: 'Revive Penguins',
            rewardText: '+3 Full Lives',
            icon: Icons.favorite_rounded,
            accentColor: const Color(0xFFE91E63),
            onRewardEarned: onRewardEarned,
          );
        },
      ),
    );
  }

  // ── Rewarded Ad: Extra Time ────────────────────────────────────────────────

  static void showRewardedTimeAd(
    BuildContext context, {
    required VoidCallback onRewardEarned,
  }) {
    // Note: Extra time bonus always requires watching a rewarded ad even in premium
    if (!isMobilePlatform || !_initialized) {
      _showSimulatedRewardDialog(
        context,
        title: 'Need More Time?',
        rewardText: '+30 Seconds Bonus',
        icon: Icons.timer_rounded,
        accentColor: const Color(0xFFFFB300),
        onRewardEarned: onRewardEarned,
      );
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (adWithoutView, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (err) {
          _showSimulatedRewardDialog(
            context,
            title: 'Need More Time?',
            rewardText: '+30 Seconds Bonus',
            icon: Icons.timer_rounded,
            accentColor: const Color(0xFFFFB300),
            onRewardEarned: onRewardEarned,
          );
        },
      ),
    );
  }

  // ── Rewarded Ad: 2x Level Rewards (Dopamine Multiplier) ────────────────────

  static void showRewardedDoubleRewardAd(
    BuildContext context, {
    required VoidCallback onRewardEarned,
  }) {
    if (!isMobilePlatform || !_initialized) {
      _showSimulatedRewardDialog(
        context,
        title: '2X Level Bonus',
        rewardText: 'Double Coins & Stars!',
        icon: Icons.card_giftcard_rounded,
        accentColor: const Color(0xFFFFD54F),
        onRewardEarned: onRewardEarned,
      );
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (adWithoutView, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (err) {
          _showSimulatedRewardDialog(
            context,
            title: '2X Level Bonus',
            rewardText: 'Double Coins & Stars!',
            icon: Icons.card_giftcard_rounded,
            accentColor: const Color(0xFFFFD54F),
            onRewardEarned: onRewardEarned,
          );
        },
      ),
    );
  }

  // ── Rewarded Ad: Emergency Huddle Rescue (Loss Aversion Save) ───────────────

  static void showRewardedRescueAd(
    BuildContext context, {
    required VoidCallback onRewardEarned,
  }) {
    // Crucial rule: even premium users must watch rewarded ad to rescue/refill lives
    if (!isMobilePlatform || !_initialized) {
      _showSimulatedRewardDialog(
        context,
        title: 'Emergency Rescue',
        rewardText: 'Revive + Shield + Keep Streak!',
        icon: Icons.healing_rounded,
        accentColor: const Color(0xFF00E676),
        onRewardEarned: onRewardEarned,
      );
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (adWithoutView, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (err) {
          _showSimulatedRewardDialog(
            context,
            title: 'Emergency Rescue',
            rewardText: 'Revive + Shield + Keep Streak!',
            icon: Icons.healing_rounded,
            accentColor: const Color(0xFF00E676),
            onRewardEarned: onRewardEarned,
          );
        },
      ),
    );
  }

  // ── Rewarded Ad: Daily Mystery Gift Chest ──────────────────────────────────

  static void showRewardedMysteryGiftAd(
    BuildContext context, {
    required VoidCallback onRewardEarned,
  }) {
    if (!isMobilePlatform || !_initialized) {
      _showSimulatedRewardDialog(
        context,
        title: 'Antarctic Mystery Chest',
        rewardText: '+250 Fish Coins Unlocked!',
        icon: Icons.card_giftcard_rounded,
        accentColor: const Color(0xFF00B0FF),
        onRewardEarned: onRewardEarned,
      );
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (adWithoutView, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (err) {
          _showSimulatedRewardDialog(
            context,
            title: 'Antarctic Mystery Chest',
            rewardText: '+250 Fish Coins Unlocked!',
            icon: Icons.card_giftcard_rounded,
            accentColor: const Color(0xFF00B0FF),
            onRewardEarned: onRewardEarned,
          );
        },
      ),
    );
  }

  // ── Simulated Fallbacks for Desktop & Test ─────────────────────────────────

  static void _showSimulatedInterstitial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _SimulatedAdDialog(
        isRewarded: false,
        title: 'Ad Preview',
        subtitle: 'Level Complete Sponsor',
      ),
    );
  }

  static void _showSimulatedRewardDialog(
    BuildContext context, {
    required String title,
    required String rewardText,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onRewardEarned,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SimulatedAdDialog(
        isRewarded: true,
        title: title,
        subtitle: rewardText,
        icon: icon,
        accentColor: accentColor,
        onReward: onRewardEarned,
      ),
    );
  }
}

// ─────────────────────────── Banner Widget ───────────────────────────────────

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (GameStorage.isAdsRemoved()) return;

    if (!AdService.isMobilePlatform) {
      setState(() => _isLoaded = true);
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (GameStorage.isAdsRemoved()) {
      return const SizedBox.shrink();
    }

    if (!AdService.isMobilePlatform) {
      // Sleek mock banner in non-mobile / emulator test mode
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF142435),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.lightBlueAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ac_unit_rounded,
                color: Colors.lightBlueAccent, size: 14),
            const SizedBox(width: 8),
            Text(
              'Huddle Up Ad Space · AdMob Active',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ─────────────────────────── Simulated Ad Dialog ─────────────────────────────

class _SimulatedAdDialog extends StatefulWidget {
  final bool isRewarded;
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onReward;

  const _SimulatedAdDialog({
    required this.isRewarded,
    required this.title,
    required this.subtitle,
    this.icon,
    this.accentColor,
    this.onReward,
  });

  @override
  State<_SimulatedAdDialog> createState() => _SimulatedAdDialogState();
}

class _SimulatedAdDialogState extends State<_SimulatedAdDialog> {
  int _secondsLeft = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    while (_secondsLeft > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _secondsLeft--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? const Color(0xFF2196F3);

    return Dialog(
      backgroundColor: const Color(0xFF101D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon ?? Icons.featured_video_rounded,
                color: color,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_secondsLeft > 0)
              Text(
                'Reward in $_secondsLeft seconds...',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(
                  widget.isRewarded ? 'Claim Reward' : 'Close Ad',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.isRewarded) {
                    widget.onReward?.call();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
