import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

class AdMobService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  // Official Google Test Ad Unit Identifiers
  static const String androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    final requestConfiguration = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
      maxAdContentRating: MaxAdContentRating.g,
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  }

  void preloadRewardedAd() {
    if (_rewardedAd != null || _isRewardedAdLoading) return;

    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: androidRewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint("AdMob: Rewarded Ad successfully cached.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          debugPrint("AdMob: Rewarded Ad cache failed: ${error.message}");
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) {
      preloadRewardedAd();
      return false;
    }

    bool earnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint("AdMob: Displayed."),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
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
