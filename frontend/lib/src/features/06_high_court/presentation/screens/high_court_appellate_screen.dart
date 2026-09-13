import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';

class HighCourtAppellateScreen extends ConsumerStatefulWidget {
  const HighCourtAppellateScreen({super.key});

  @override
  ConsumerState<HighCourtAppellateScreen> createState() => _HighCourtAppellateScreenState();
}

class _HighCourtAppellateScreenState extends ConsumerState<HighCourtAppellateScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hasJudgmentUploaded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'nav_regional_hud',
        subtitleKey: 'court_jurisdiction',
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),

          // Executive Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(
              color: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? LuxuryPalette.midnightSurface : LuxuryPalette.courtNavy,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: LuxuryPalette.champagneGold, width: 1.0),
              ),
              labelColor: LuxuryPalette.champagneGold,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black87,
              labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'अपील / पुनरीक्षण मेमो'),
                Tab(text: 'दंडादेश स्थगन (Sec 389)'),
                Tab(text: 'विलंब माफी (Sec 5)'),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
              children: [
                // 1. Certified Copy OCR Upload Dropzone
                _buildOcrDropzone(isDark),
                const SizedBox(height: 12),

                // 2. Section 12 Limitation Act Deduction Counter
                _buildLimitationCounterCard(isDark),
                const SizedBox(height: 12),

                // 3. Extracted Conviction & Sentence Ratio Card
                if (_hasJudgmentUploaded) _buildConvictionRatioCard(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrDropzone(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 36, color: LuxuryPalette.champagneGold),
          const SizedBox(height: 8),
          const Text('सत्र न्यायालय निर्णय / आदेश प्रमाणित प्रति अपलोड करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 4),
          Text(
            'PyMuPDF + Gemini Flash OCR • Head-and-Tail Smart Sampling (दोषसिद्धि व धारा 313 दोष)',
            style: TextStyle(fontSize: 11, color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxuryPalette.courtNavy,
              foregroundColor: LuxuryPalette.lightSurface,
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('निर्णय PDF अपलोड करें एवं विश्लेषण शुरू करें', style: TextStyle(fontSize: 12)),
            onPressed: () {
              setState(() => _hasJudgmentUploaded = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLimitationCounterCard(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text('म्याद गणना (Limitation Calculator)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 8),
              LuxuryBadge(
                label: 'धारा 12 नकल अवधि कटौती सक्रिय',
                foregroundColor: LuxuryPalette.emeraldVerified,
                backgroundColor: LuxuryPalette.emeraldBgLight,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'निर्णय दिनांक से 60 दिन (अपील Art 115) • नकल आवेदन से प्राप्ति के 14 दिन सांविधिक रूप से घटाए गए।',
            style: TextStyle(fontSize: 11.5, color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildConvictionRatioCard(bool isDark) {
    return LuxuryCard(
      hasGoldAccent: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text('सत्र वाद सं. 412/2021 दोषसिद्धि विश्लेषण', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              SizedBox(width: 8),
              LuxuryBadge(
                label: '7 वर्ष सश्रम कारावास',
                foregroundColor: LuxuryPalette.rubyAlert,
                backgroundColor: LuxuryPalette.rubyBgLight,
              ),
            ],
          ),
          const Divider(height: 14),
          const Text('पहचाने गए अपील आधार (Appellate Grounds):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('1. धारा 313 बयान में परिस्थितिजन्य साक्ष्य अभियुक्त के समक्ष न रखना (गंभीर विधिक त्रुटि)।', style: TextStyle(fontSize: 11.5)),
          const Text('2. PW-1 व PW-2 के बयानों में घटनास्थल के संबंध में स्पष्ट अंतर्विरोध।', style: TextStyle(fontSize: 11.5)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: LuxuryPalette.courtNavy,
                foregroundColor: LuxuryPalette.lightSurface,
              ),
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('1.75" बाइंडिंग मार्जिन सहित पेपर-बुक निर्यात करें (High Court PDF)'),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
