import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/stitch_colors.dart';
import '../../features/billing/data/admob_service.dart';
import '../../features/billing/presentation/controllers/subscription_controller.dart';

class CourtInlineBannerAd extends ConsumerStatefulWidget {
  const CourtInlineBannerAd({super.key});

  @override
  ConsumerState<CourtInlineBannerAd> createState() => _CourtInlineBannerAdState();
}

class _CourtInlineBannerAdState extends ConsumerState<CourtInlineBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPro = ref.read(isProSubscriberProvider);
      if (!isPro) {
        _loadAd();
      }
    });
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService.androidBannerTestId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
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
    final isPro = ref.watch(isProSubscriberProvider);
    if (isPro) return const SizedBox.shrink();

    if (!_isAdLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: StitchColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
            child: Text(
              'प्रायोजित विधिक सूचना (Sponsored)',
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
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
