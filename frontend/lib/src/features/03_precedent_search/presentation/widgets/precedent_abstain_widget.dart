import 'package:flutter/material.dart';
import '../../../../core/theme/stitch_colors.dart';

class PrecedentAbstainWidget extends StatelessWidget {
  final String queryTerm;

  const PrecedentAbstainWidget({super.key, required this.queryTerm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: StitchColors.unverifiedAmberBg,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: StitchColors.unverifiedAmber, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: StitchColors.unverifiedAmber, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'कोई पुष्ट कानूनी मिसाल (Precedent) नहीं मिली',
                  style: TextStyle(
                    color: StitchColors.unverifiedAmber,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'आपके द्वारा दर्ज किए गए तथ्यों ("$queryTerm") हेतु हमारे सत्यापित भंडार में न्यूनतम 65% प्रासंगिक निर्णय उपलब्ध नहीं है।',
            style: const TextStyle(
              color: StitchColors.textPrimary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'अधिवक्ता आचार संहिता (BCI Rule 5) एवं न्यायालयीन शुचिता बनाए रखने हेतु प्रणाली ने कोई काल्पनिक केस-लॉ नहीं गढ़ा है।',
            style: TextStyle(
              color: StitchColors.textSecondary,
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: StitchColors.courtNavy),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'सुझाव: कृपया जिला विधिक पुस्तकालय, ई-कोर्ट्स, अथवा उच्च न्यायालय डायजेस्ट पर मैन्युअल शोध करें।',
                    style: TextStyle(fontSize: 11.5, color: StitchColors.courtNavy, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
