import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/admob_constants.dart';

final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

class AdMobService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  int _loadRetryAttempts = 0;

  // Official Google Fallback Test Units (Maintained for backwards-compatibility)
  static const String androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  /// Initializes Mobile Ads SDK with test device whitelisting & BCI compliance
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    final requestConfiguration = RequestConfiguration(
      testDeviceIds: AdMobConstants.testDeviceIds,
      ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
      maxAdContentRating: MaxAdContentRating.g, // Professional legal audience
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    debugPrint('[AdMob Engine] MobileAds requestConfiguration updated with ${AdMobConstants.testDeviceIds.length} test devices.');
  }

  /// Preloads Rewarded Ad in background with exponential backoff on network failure
  void preloadRewardedAd() {
    if (_rewardedAd != null || _isRewardedAdLoading) return;

    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: AdMobConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _loadRetryAttempts = 0;
          debugPrint("[AdMob Engine] Rewarded Ad successfully cached in memory.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          _loadRetryAttempts++;
          debugPrint("[AdMob Engine] Rewarded Ad load failed (Attempt $_loadRetryAttempts): ${error.message}");

          if (_loadRetryAttempts <= 3) {
            Future.delayed(Duration(seconds: _loadRetryAttempts * 4), () {
              preloadRewardedAd();
            });
          }
        },
      ),
    );
  }

  /// Displays Rewarded Ad and returns validation result
  Future<bool> showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) {
      debugPrint("[AdMob Engine] Ad not ready on trigger. Initiating urgent fetch.");
      preloadRewardedAd();
      return false;
    }

    bool earnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("[AdMob Engine] Fullscreen Rewarded Video presented.");
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd(); // Keep queue warm for future unlocks
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("[AdMob Engine] Failed to present ad: ${error.message}");
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (adWithoutView, reward) {
        earnedReward = true;
        onUserEarnedReward(reward);
      },
    );

    return earnedReward;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
