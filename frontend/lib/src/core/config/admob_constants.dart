import 'package:flutter/foundation.dart';

class AdMobConstants {
  // Official Asiverticals AdMob Production App Identifiers
  static const String androidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-8451920384729104~9384720194',
  );

  // Production Ad Units (Native Inline Banner & Rewarded Video)
  static const String _androidBannerProdId = String.fromEnvironment(
    'ADMOB_BANNER_PROD_ID',
    defaultValue: 'ca-app-pub-8451920384729104/1029384756',
  );
  static const String _androidRewardedProdId = String.fromEnvironment(
    'ADMOB_REWARDED_PROD_ID',
    defaultValue: 'ca-app-pub-8451920384729104/5647382910',
  );

  // Official Google Fallback Test Units (Used during local debug runs only)
  static const String _androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  /// Whitelisted Developer Physical Test Device Hashed IDs
  /// Enforces real ad unit rendering without triggering Google AdSense invalid traffic bans
  static const List<String> testDeviceIds = [
    'B3EEABB8EE11C2BE770B684D95219ECB', // Internal QA Device 1 (OnePlus Nord)
    'F5A9A7A6D889E4C2E3C0F5D5881C8E64', // Internal QA Device 2 (Samsung Galaxy M34)
    '2C9A1D8A3B4C5E6F7A8B9C0D1E2F3A4B', // Core Dev Workstation Emulator
  ];

  static String get bannerAdUnitId {
    if (kDebugMode || const bool.fromEnvironment('USE_TEST_ADS', defaultValue: false)) {
      return _androidBannerTestId;
    }
    return _androidBannerProdId;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode || const bool.fromEnvironment('USE_TEST_ADS', defaultValue: false)) {
      return _androidRewardedTestId;
    }
    return _androidRewardedProdId;
  }
}
