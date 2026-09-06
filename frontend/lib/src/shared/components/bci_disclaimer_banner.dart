import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

class BciDisclaimerBanner extends StatelessWidget {
  final bool compact;

  const BciDisclaimerBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: compact ? 6.0 : 8.0),
      color: StitchColors.chamberSlate,
      child: const Row(
        children: [
          Icon(Icons.gavel_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'विधिक अस्वीकरण (BCI नियम 5): यह प्रणाली केवल अनुसंधान एवं मसौदा सहायक है। '
              'न्यायालय में उपयोग से पूर्व अधिवक्ता द्वारा स्वतंत्र पेशेवर विवेक का प्रयोग अनिवार्य है।',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.40,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
