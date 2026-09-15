import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/responsive_court_tab_bar.dart';
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

          // Responsive Scrollable Tab Bar
          ResponsiveCourtTabBar(
            controller: _tabController,
            isDark: isDark,
            tabs: [
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_bsa_cert'),
                icon: Icons.fingerprint_rounded,
                badgeText: 'Sec 63 BSA',
              ),
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_medico_legal'),
                icon: Icons.medical_services_outlined,
                badgeText: 'PMR Conflict',
              ),
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_malkhana'),
                icon: Icons.inventory_2_outlined,
                badgeText: 'Reg No. 19',
              ),
            ],
          ),

          // Tab Views
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
