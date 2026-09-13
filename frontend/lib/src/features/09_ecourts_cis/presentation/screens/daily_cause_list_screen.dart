import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';

class DailyCauseListScreen extends ConsumerStatefulWidget {
  const DailyCauseListScreen({super.key});

  @override
  ConsumerState<DailyCauseListScreen> createState() => _DailyCauseListScreenState();
}

class _DailyCauseListScreenState extends ConsumerState<DailyCauseListScreen> {
  int _dayToggleIndex = 0; // 0: Today, 1: Tomorrow
  int _filterIndex = 0;

  final List<String> _filters = ['सभी वाद (14)', 'मेरे चैंबर के वाद (3)', 'पुकार हुई (Live)'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'today_hearings',
        subtitleKey: 'court_jurisdiction',
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),

          // Day Toggle Segment
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('आज की सूची (Today)')),
                    selected: _dayToggleIndex == 0,
                    selectedColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _dayToggleIndex == 0 ? (isDark ? Colors.black : Colors.white) : Colors.grey,
                    ),
                    onSelected: (val) => setState(() => _dayToggleIndex = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('कल की सूची (Tomorrow)')),
                    selected: _dayToggleIndex == 1,
                    selectedColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _dayToggleIndex == 1 ? (isDark ? Colors.black : Colors.white) : Colors.grey,
                    ),
                    onSelected: (val) => setState(() => _dayToggleIndex = 1),
                  ),
                ),
              ],
            ),
          ),

          // Sub-filters
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _filters.length,
              itemBuilder: (ctx, idx) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(_filters[idx], style: const TextStyle(fontSize: 11)),
                  selected: _filterIndex == idx,
                  selectedColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _filterIndex == idx ? (isDark ? Colors.black : Colors.white) : Colors.grey,
                  ),
                  onSelected: (_) => setState(() => _filterIndex = idx),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Docket Listing
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
              children: [
                _buildCauseItem(
                  itemNo: '04',
                  caseNo: 'मु.अ.सं. 124/2026',
                  courtRoom: 'कक्ष संख्या 14 (CJM, लखनऊ)',
                  parties: 'राज्य बनाम रामू उर्फ राम प्रकाश',
                  stage: 'जमानत प्रार्थना पत्र सुनवाई (Bail Hearing)',
                  isMyChamber: true,
                  isDark: isDark,
                ),
                _buildCauseItem(
                  itemNo: '12',
                  caseNo: 'मु.अ.सं. 89/2026',
                  courtRoom: 'विशेष न्यायालय NDPS Act (कोर्ट 03)',
                  parties: 'राज्य बनाम दिनेश कुमार',
                  stage: 'आरोप विरचन (Framing of Charge)',
                  isMyChamber: true,
                  isDark: isDark,
                ),
                _buildCauseItem(
                  itemNo: '28',
                  caseNo: 'मु.अ.सं. 402/2025',
                  courtRoom: 'अपर सत्र न्यायाधीश (कोर्ट 08)',
                  parties: 'राज्य बनाम विकास सिंह',
                  stage: 'साक्ष्य अभियोजन (PW-1 Examination)',
                  isMyChamber: false,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCauseItem({
    required String itemNo,
    required String caseNo,
    required String courtRoom,
    required String parties,
    required String stage,
    required bool isMyChamber,
    required bool isDark,
  }) {
    return LuxuryCard(
      hasGoldAccent: isMyChamber,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isMyChamber ? LuxuryPalette.champagneGold : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                const Text('क्रम', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(itemNo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(caseNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    if (isMyChamber)
                      const LuxuryBadge(
                        label: 'मेरा चैंबर',
                        foregroundColor: LuxuryPalette.champagneGold,
                        backgroundColor: LuxuryPalette.midnightElevated,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(parties, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                Text(courtRoom, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? LuxuryPalette.midnightElevated : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(stage, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: LuxuryPalette.sapphireNotice)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
