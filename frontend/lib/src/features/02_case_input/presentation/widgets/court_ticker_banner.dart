import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/luxury_palette.dart';

class CourtTickerBanner extends ConsumerStatefulWidget {
  const CourtTickerBanner({super.key});

  @override
  ConsumerState<CourtTickerBanner> createState() => _CourtTickerBannerState();
}

class _CourtTickerBannerState extends ConsumerState<CourtTickerBanner> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<AppLanguage, String>> _tickerItems = [
    {
      AppLanguage.hindi: '🚨 धारा 187 BNSS: 2 वादों में 60/90 दिवसीय डिफ़ॉल्ट जमानत की अवधि आज समाप्त हो रही है।',
      AppLanguage.english: '🚨 Sec 187 BNSS: Statutory default bail crystallizing today in 2 criminal dockets.',
    },
    {
      AppLanguage.hindi: '⚖️ दैनिक कॉज लिस्ट: मुख्य न्यायिक मजिस्ट्रेट, लखनऊ के समक्ष 3 वाद आज सुनवाई हेतु सूचीबद्ध हैं।',
      AppLanguage.english: "⚖️ Daily Cause List: 3 defense matters listed today before CJM, Lucknow Bench.",
    },
    {
      AppLanguage.hindi: '📜 धारा 479 BNSS: विचाराधीन बंदी 1/3 सजा पूरी करने पर रिहाई हेतु पात्र पाया गया।',
      AppLanguage.english: '📜 Sec 479 BNSS: 1 undertrial eligible for immediate discharge under 1/3rd rule.',
    },
    {
      AppLanguage.hindi: '⚡ लाइव कोर्टरूम HUD सक्रिय: सब-500ms में अभियोजन तर्कों का विधिक खंडन उपलब्ध।',
      AppLanguage.english: '⚡ Live Courtroom HUD Active: Sub-500ms counter-ratios ready for oral hearings.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _tickerItems.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentText = _tickerItems[_currentIndex][lang] ?? _tickerItems[_currentIndex][AppLanguage.hindi]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A30) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark
              ? LuxuryPalette.midnightBorderSubtle
              : LuxuryPalette.champagneGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: LuxuryPalette.champagneGold,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lang == AppLanguage.hindi ? 'अधिसूचना' : 'ALERT',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: LuxuryPalette.courtNavy,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                currentText,
                key: ValueKey<int>(_currentIndex),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? LuxuryPalette.darkTextPrimary : LuxuryPalette.courtNavy,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
