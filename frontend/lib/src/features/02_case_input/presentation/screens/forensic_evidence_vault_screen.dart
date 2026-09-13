import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../views/electronic_evidence_tab_view.dart';
import '../views/medico_legal_matrix_tab_view.dart';
import '../views/malkhana_chain_tab_view.dart';

class ForensicEvidenceVaultScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const ForensicEvidenceVaultScreen({
    super.key,
    this.caseId = 'UP-CR-2026-902',
    this.accusedName = 'अभियुक्त (Accused)',
    this.policeStation = 'कोतवाली नगर',
    this.district = 'लखनऊ',
  });

  @override
  ConsumerState<ForensicEvidenceVaultScreen> createState() => _ForensicEvidenceVaultScreenState();
}

class _ForensicEvidenceVaultScreenState extends ConsumerState<ForensicEvidenceVaultScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
        titleKey: 'nav_forensics',
        subtitleKey: 'defense_hub_sub',
        showBackButton: false,
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),

          // Executive Tab Segment Bar
          Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? LuxuryPalette.midnightSurface : LuxuryPalette.courtNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: LuxuryPalette.champagneGold.withValues(alpha: 0.7),
                  width: 1.0,
                ),
              ),
              labelColor: LuxuryPalette.champagneGold,
              unselectedLabelColor: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
              labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: AppStrings.tr(ref, 'mod_bsa_cert').split('(').first.trim()),
                Tab(text: AppStrings.tr(ref, 'mod_medico_legal').split(' ').first.trim()),
                Tab(text: AppStrings.tr(ref, 'mod_malkhana').split(' ').first.trim()),
              ],
            ),
          ),

          // Tab Content Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ElectronicEvidenceTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                MedicoLegalMatrixTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                MalkhanaChainTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
