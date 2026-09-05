import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';
import '../../core/theme/stitch_typography.dart';

class PrecedentAbstainWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onManualResearch;

  const PrecedentAbstainWidget({
    super.key,
    this.message,
    this.onManualResearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: StitchColors.unverifiedAmberBg,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: StitchColors.unverifiedAmber.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel,
                color: StitchColors.unverifiedAmber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'सटीकता सीमा: 65% से कम (Zero-Hallucination Guard)',
                  style: StitchTypography.title(
                    color: StitchColors.unverifiedAmber,
                    size: 13.5,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message ??
                'आपके द्वारा दर्ज तथ्यों के लिए कोई 65%+ पुष्ट कानूनी मिसाल नहीं मिली। भ्रामक या काल्पनिक संदर्भों से बचाव हेतु प्रणाली ने उत्तर रोक दिया है। कृपया बार लाइब्रेरी या आधिकारिक विधि रिपोर्ट से मैन्युअल शोध करें।',
            style: StitchTypography.body(
              color: const Color(0xFF782508),
              size: 13.0,
              height: 1.45,
            ),
          ),
          if (onManualResearch != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onManualResearch,
                icon: const Icon(Icons.search, size: 16, color: StitchColors.unverifiedAmber),
                label: Text(
                  'मैन्युअल कीवर्ड खोजें',
                  style: StitchTypography.label(
                    color: StitchColors.unverifiedAmber,
                    size: 12.0,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
