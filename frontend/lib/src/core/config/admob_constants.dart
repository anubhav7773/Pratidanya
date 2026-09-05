import 'package:flutter/foundation.dart';

class AdMobConstants {
  // Official Google AdMob Test IDs
  static const String _androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  // Production IDs (Asiverticals Pratidnya App Units)
  static const String _androidBannerProdId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const String _androidRewardedProdId = String.fromEnvironment('ADMOB_REWARDED_ID');

  static String get bannerAdUnitId {
    if (kDebugMode || const bool.fromEnvironment('USE_TEST_ADS', defaultValue: true)) {
      return _androidBannerTestId;
    }
    return _androidBannerProdId.isNotEmpty ? _androidBannerProdId : _androidBannerTestId;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode || const bool.fromEnvironment('USE_TEST_ADS', defaultValue: true)) {
      return _androidRewardedTestId;
    }
    return _androidRewardedProdId.isNotEmpty ? _androidRewardedProdId : _androidRewardedTestId;
  }
}
