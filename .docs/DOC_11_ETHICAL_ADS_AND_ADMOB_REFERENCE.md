================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-11
MODULE         : ETHICAL ADMOB INTEGRATION, BCI RULE 36 & REWARDED QUOTA ENGINE
TARGET RUNTIME : Flutter (google_mobile_ads ^5.1.0) / FastAPI / Supabase
MONETIZATION   : Google AdMob (Native Inline Banners & Rewarded Video Units)
ETHICAL POLICY : Bar Council of India Rule 36 Compliance (Zero Frustration UX)
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. ETHICAL MONETIZATION PHILOSOPHY & BCI RULE 36 COMPLIANCEDistrict Court criminal lawyers court corridors aur chambers mein extreme time pressure, bail hearings aur chargesheet arguments ke beech mobile app use karte hain. Is sensitive professional environment mein intrusive, loud, ya deceptive ads na sirf user ko frustrate karte hain, balki Bar Council of India (BCI) Rules on Professional Standards ka bhi ullanghan karte hain:  ┌────────────────────────────────────────────────────────────────────────┐
│                     BCI RULE 36 ADVERTISING ETHICS                    │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Zero Interstitials during drafting or court arguments               │
│ 2. Zero Sensational claims ("100% जमानत गारंटी", "सर्वश्रेष्ठ वकील")    │
│ 3. Zero Click-traps, intrusive overlays, or auto-playing loud audio    │
│ 4. Strictly Sobriety & Professional Decorum in ad presentation         │
└────────────────────────────────────────────────────────────────────────┘
Permissible vs. Prohibited Ad TaxonomyAd FormatOperational StatusAllowed LocationImplementation RuleInterstitial Ads (Full Screen)STRICTLY PROHIBITEDNowhereAI draft generation, reading court orders, ya argument preparation ke waqt screen hijack karna strictly banned hai.App Open AdsPROHIBITEDApp StartupLawyer court hearing ke dauran app open kare aur ad aa jaye toh critical delay hota hai. Startup ad block rahega.Native Inline BannersALLOWEDCase Diary List (Bottom / In-feed)Subtle, static, muted palette ke sath. Feed mein har 6 cases ke baad ek inline banner render ho sakta hai.Rewarded Video AdsALLOWED (Opt-In Only)Quota Exhaustion DialogJab daily free quota (3 drafts) khatam ho, lawyer apni marzi se select kare: "1 अतिरिक्त AI ड्राफ्ट हेतु विज्ञापन देखें".2. GOOGLE ADMOB CONSOLE SENSITIVE CATEGORY BLOCKINGProduction AdMob dashboard par Asiverticals account ke andar niche di gayi categories ko Block karna mandatory hai taaki legal decorum bana rahe:Blocked Sensitive Categories (AdMob Dashboard ➔ Blocking Controls):Gambling, Betting & Casinos: (Dream11, Rummy, Poker, etc. strictly blocked).Sensational Personal Loans & Instant Cash: (Predatory lending apps blocked).Dating, Adult & Matrimonial Romance: (Strictly blocked).Astrology, Occult & Superstitions: (Strictly blocked).Deceptive Legal & Bail Guarantees: (Third-party misleading legal services blocked).  Allowed Neutral Categories:Professional Office Tech & Hardware (Laptops, Printers, Scanners).Legal & Civil Services Publications (Standard Law Books, Bare Acts).Commercial Cloud & Chamber Productivity SaaS.Telecom & Banking Infrastructure.3. PLATFORM SETUP & TEST AD UNIT IDSA. Dependencies (pubspec.yaml)YAMLdependencies:
  google_mobile_ads: ^5.1.0
B. Android Configuration (android/app/src/main/AndroidManifest.xml)<application> tag ke andar Google Play Services Ads application ID define karni hai:XML<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="प्रतिज्ञा"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Google AdMob Official Application ID -->
        <!-- Replace with real AdMob App ID in production build -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>

        <!-- Optional: Enable optimize initialization -->
        <meta-data
            android:name="com.google.android.gms.ads.flag.OPTIMIZE_INITIALIZATION"
            android:value="true"/>
    </application>
</manifest>
C. Official Google AdMob Test Ad Unit IdentifiersDevelopment aur local testing ke dauran production IDs use karna Google Play policy ka violation hai (Account suspension risk). Antigravity ko strictly in official test IDs ka use karna hai:Ad TypePlatformOfficial Google Test Ad Unit IDBanner / Inline NativeAndroidca-app-pub-3940256099942544/6300978111Rewarded VideoAndroidca-app-pub-3940256099942544/5224354917BanneriOSca-app-pub-3940256099942544/2934735716Rewarded VideoiOSca-app-pub-3940256099942544/1712485313Dart// lib/src/core/config/admob_constants.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class AdMobConstants {
  // Test IDs (Google Official)
  static const String _androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  // Production IDs (Asiverticals Pratidnya App Units)
  static const String _androidBannerProdId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const String _androidRewardedProdId = String.fromEnvironment('ADMOB_REWARDED_ID');

  static String get bannerAdUnitId {
    if (kDebugMode || const bool.fromEnvironment('USE_TEST_ADS', defaultValue: true)) {
      return _androidBannerTestId;
    }
    return _androidBannerProdId;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode || const bool.fromEnvironment('USE_TEST_ADS', defaultValue: true)) {
      return _androidRewardedTestId;
    }
    return _androidRewardedProdId;
  }
}
4. ADMOB SERVICE ENGINE (DART / RIVERPOD 2.X)Ad initialization, background loading, memory leaks prevention, aur rewarded callbacks ko manage karne ka centralized service engine:Dart// lib/src/features/billing/data/admob_service.dart
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

  /// Initialize Mobile Ads SDK during app startup
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Set request configuration for child/general audience
    final requestConfiguration = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
      maxAdContentRating: MaxAdContentRating.g, // Family & Professional legal audience
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  }

  /// Preload Rewarded Ad in background
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
          debugPrint("AdMob: Rewarded Ad successfully loaded in cache.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          debugPrint("AdMob: Rewarded Ad failed to load: ${error.message}");
        },
      ),
    );
  }

  /// Show Rewarded Ad with verification callback
  Future<bool> showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) {
      debugPrint("AdMob: Rewarded Ad not ready. Preloading for next attempt.");
      preloadRewardedAd();
      return false;
    }

    bool earnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("AdMob: Rewarded Ad shown on screen.");
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Preload next ad for future use
        preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("AdMob: Rewarded Ad failed to show: ${error.message}");
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
5. SUBTLE NATIVE INLINE BANNER WIDGETCase Diary list ke andar integrate hone wala clean, court-decorum compliant banner widget:Dart// lib/src/shared/components/court_inline_banner_ad.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/admob_constants.dart';
import '../../core/theme/app_colors.dart';

class CourtInlineBannerAd extends StatefulWidget {
  const CourtInlineBannerAd({super.key});

  @override
  State<CourtInlineBannerAd> createState() => _CourtInlineBannerAdState();
}

class _CourtInlineBannerAdState extends State<CourtInlineBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdMobConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Inline Banner Failed: ${error.message}");
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // Takes zero space when ad fails or loads
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
            child: Text(
              'प्रायोजित (Sponsored)',
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}
6. BACKEND REWARD VERIFICATION & QUOTA UNLOCKClient par ad complete hone par reward direct increment nahi hoga; client backend endpoint /api/v1/billing/claim-ad-reward par request bhejega jahan abuse-prevention checks (Daily limit max 3 rewarded ads) execute honge:FastAPI Backend Handler (billing.py)Python# app/api/v1/endpoints/billing.py (Snippet)
from datetime import date
from fastapi import APIRouter, HTTPException, Security
from app.core.security import verify_advocate_token
from app.core.supabase_client import get_supabase_admin_client

router = APIRouter(prefix="/billing", tags=["Billing & Quota"])

MAX_REWARDED_ADS_PER_DAY = 3

@router.post("/claim-ad-reward")
async def claim_ad_reward(current_user: dict = Security(verify_advocate_token)):
    """
    Increments advocate's ad_rewarded_drafts count after watching an ad.
    Enforces maximum 3 rewarded unlocks per day to avoid spam/botting.
    """
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    # Step 1: Fetch current quota record
    quota_res = supabase.table("advocate_ai_quotas") \
        .select("ad_rewarded_drafts, last_quota_reset_date, subscription_tier") \
        .eq("advocate_id", advocate_id) \
        .single() \
        .execute()

    quota = quota_res.data
    if quota["subscription_tier"] == "PRO_CHAMBER":
        return {"status": "ALREADY_PRO", "message": "प्रो चैंबर में असीमित कोटा पहले से सक्रिय है।"}

    current_rewarded = quota.get("ad_rewarded_drafts", 0)

    # Step 2: Enforce daily ceiling
    if current_rewarded >= MAX_REWARDED_ADS_PER_DAY:
        raise HTTPException(
            status_code=429,
            detail=f"दैनिक विज्ञापन सीमा समाप्त: आप प्रतिदिन अधिकतम {MAX_REWARDED_ADS_PER_DAY} बार "
                   f"ही विज्ञापन द्वारा ड्राफ्ट अनलॉक कर सकते हैं।"
        )

    # Step 3: Increment Ad-Rewarded Quota by +1 Draft
    new_count = current_rewarded + 1
    supabase.table("advocate_ai_quotas") \
        .update({
            "ad_rewarded_drafts": new_count,
            "updated_at": "now()"
        }) \
        .eq("advocate_id", advocate_id) \
        .execute()

    return {
        "status": "SUCCESS",
        "ad_rewarded_drafts_available": new_count,
        "message": "1 अतिरिक्त AI विधिक ड्राफ्ट सफलतापूर्वक अनलॉक किया गया।"
    }
7. USER-FACING QUOTA EXHAUSTION MODALJab advocate ka 3 daily free drafts ka quota khatam ho, toh yeh clear opt-in modal render hoga:Dart// lib/src/features/04_draft_generator/presentation/widgets/quota_exhausted_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../billing/data/admob_service.dart';

Future<bool> showQuotaExhaustedDialog({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onUpgradeToProPressed,
  required Future<void> Function() onRewardClaimed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      title: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: AppColors.unverifiedAmber, size: 26),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'दैनिक निःशुल्क कोटा समाप्त',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        'आज के लिए आपके 3 निःशुल्क विधिक ड्राफ्ट उपयोग हो चुके हैं।\n\n'
        'कार्य जारी रखने के लिए आप एक संक्षिप्त विज्ञापन देखकर 1 अतिरिक्त ड्राफ्ट अनलॉक कर सकते हैं '
        'अथवा प्रो चैंबर में अपग्रेड कर सकते हैं।',
        style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.star_rounded, color: Colors.amber),
          label: const Text('प्रो में अपग्रेड करें'),
          onPressed: () {
            Navigator.pop(ctx, false);
            onUpgradeToProPressed();
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.courtNavy,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: const Text('+1 ड्राफ्ट देखें'),
          onPressed: () async {
            Navigator.pop(ctx, true);
          },
        ),
      ],
    ),
  );

  if (result == true) {
    // Trigger AdMob Rewarded Ad
    final adService = ref.read(admobServiceProvider);
    final earned = await adService.showRewardedAd(
      onUserEarnedReward: (reward) async {
        await onRewardClaimed();
      },
    );
    return earned;
  }

  return false;
}
8. PRO SUBSCRIBER AD-SUPPRESSION GUARANTEEAgar advocate ne Chamber Pro monthly ya yearly plan liya hua hai, toh UI layer mein ads automatically suppress ho jaayenge:Dart// Check in widgets rendering banners:
final isProUser = ref.watch(isProSubscriberProvider);

if (isProUser) {
  return const SizedBox.shrink(); // Zero AdMob widgets initialized or displayed
}
9. ANTIGRAVITY NON-NEGOTIABLE ADMOB CHECKLIST (DOC-11)Antigravity code likhte waqt in exact technical assertions ko verify karega:[ ] No Interstitial Ads will be loaded or displayed during Bail drafting, Case analysis, or Verification Gate workflows.[ ] Test Ad Unit IDs must be used whenever kDebugMode == true or USE_TEST_ADS == true to prevent Play Store suspensions.[ ] Rewarded ads must always preload in the background (preloadRewardedAd()) to prevent user waiting delays.[ ] Quota unlock after watching an ad must be validated by calling the backend /claim-ad-reward endpoint.[ ] If the user has an active Pro subscription, all AdMob widgets and network calls must be completely disabled (SizedBox.shrink()).[ ] Ads must be styled with sober, professional borders; no neon colors or misleading labels.