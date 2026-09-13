import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';

class PrecedentSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final List<String>? initialSections;

  const PrecedentSearchScreen({
    super.key,
    this.initialQuery,
    this.initialSections,
  });

  @override
  ConsumerState<PrecedentSearchScreen> createState() => _PrecedentSearchScreenState();
}

class _PrecedentSearchScreenState extends ConsumerState<PrecedentSearchScreen> {
  late final TextEditingController _searchController;
  int _selectedBenchIndex = 0;
  bool _isSearching = false;

  final List<String> _benchFilters = [
    'उच्चतम न्यायालय (SC)',
    'इलाहाबाद उच्च न्यायालय',
    'जमानत मिसालें (Bail)',
    'अंतिम 5 वर्ष',
    'दिल्ली उच्च न्यायालय',
    'समस्त उच्च न्यायालय',
  ];

  final List<_PrecedentRecord> _samplePrecedents = [
    _PrecedentRecord(
      caseTitle: 'सतेन्द्र कुमार अंतिल बनाम सी.बी.आई. (2022) 10 SCC 51',
      citation: 'AIR 2022 SC 3386',
      court: 'Supreme Court of India',
      similarityScore: 0.94,
      legalRatioHindi: '7 वर्ष तक कारावास वाले अपराधों में बिना गिरफ्तारी समन जारी होगा। यांत्रिक रिमांड पारित करने वाले मजिस्ट्रेट अनुशासनात्मक कार्रवाई के उत्तरदायी हैं।',
      verifiedUrl: 'https://main.sci.gov.in/judgment/judis/49524.pdf',
      statutoryTags: ['Section 41A CrPC', 'Section 35 BNSS', 'Bail Category A'],
    ),
    _PrecedentRecord(
      caseTitle: 'बिक्रमजीत सिंह बनाम पंजाब राज्य (2020) 10 SCC 616',
      citation: 'AIR 2020 SC 4924',
      court: 'Supreme Court of India',
      similarityScore: 0.89,
      legalRatioHindi: 'डिफ़ॉल्ट जमानत अनुच्छेद 21 के अंतर्गत मौलिक अधिकार है। 60/90 दिन बीतते ही यह अधिकार अचूक रूप से प्रोद्भूत हो जाता है।',
      verifiedUrl: 'https://main.sci.gov.in/judgment/judis/47746.pdf',
      statutoryTags: ['Section 167(2) CrPC', 'Section 187 BNSS', 'Default Bail'],
    ),
    _PrecedentRecord(
      caseTitle: 'फरहाना बनाम उत्तर प्रदेश राज्य (2024) 4 SCC 685',
      citation: '2024 INSC 121',
      court: 'Supreme Court of India',
      similarityScore: 0.86,
      legalRatioHindi: 'आधारभूत पूर्व मुकदमों में दोषमुक्ति अथवा एफआईआर निरस्त होने पर उ.प्र. गिरोहबंद अधिनियम की कार्यवाही जीवित नहीं रह सकती।',
      verifiedUrl: 'https://main.sci.gov.in/judgment/judis/50412.pdf',
      statutoryTags: ['UP Gangsters Act', 'Rule 16', 'Quashing Article 226'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'mod_witness_grid',
        subtitleKey: 'chamber_badge',
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),

          // Search Bar & Mic Action
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'तथ्य, धाराएं या विधिक प्रश्न दर्ज करें (उदा. Section 52A NDPS sampling)...',
                prefixIcon: const Icon(Icons.search_rounded, color: LuxuryPalette.champagneGold),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: LuxuryPalette.champagneGold),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.mic_none_rounded, color: LuxuryPalette.champagneGold),
                        onPressed: () {},
                      ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) {
                setState(() => _isSearching = true);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _isSearching = false);
                });
              },
            ),
          ),

          // Bench Filter Chips
          SizedBox(
            height: 38,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                children: List.generate(_benchFilters.length, (index) {
                  final isSelected = _selectedBenchIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_benchFilters[index]),
                      selected: isSelected,
                      selectedColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark ? LuxuryPalette.courtNavy : Colors.white)
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (val) => setState(() => _selectedBenchIndex = index),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Precedent Result Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
              itemCount: _samplePrecedents.length,
              itemBuilder: (context, index) {
                final item = _samplePrecedents[index];
                return _buildPrecedentCard(item, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecedentCard(_PrecedentRecord item, bool isDark) {
    return LuxuryCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.caseTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              LuxuryBadge(
                label: '${(item.similarityScore * 100).toInt()}% Match',
                foregroundColor: LuxuryPalette.emeraldVerified,
                backgroundColor: LuxuryPalette.emeraldBgLight,
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${item.citation} • ${item.court}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
            ),
          ),
          const Divider(height: 14),

          Text(
            item.legalRatioHindi,
            style: const TextStyle(fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            children: item.statutoryTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          InkWell(
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 14, color: LuxuryPalette.sapphireNotice),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.verifiedUrl,
                    style: const TextStyle(fontSize: 11, color: LuxuryPalette.sapphireNotice, decoration: TextDecoration.underline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _PrecedentRecord {
  final String caseTitle;
  final String citation;
  final String court;
  final double similarityScore;
  final String legalRatioHindi;
  final String verifiedUrl;
  final List<String> statutoryTags;

  _PrecedentRecord({
    required this.caseTitle,
    required this.citation,
    required this.court,
    required this.similarityScore,
    required this.legalRatioHindi,
    required this.verifiedUrl,
    required this.statutoryTags,
  });
}
