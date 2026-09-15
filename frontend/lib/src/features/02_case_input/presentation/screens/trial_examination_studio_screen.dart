import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/responsive_court_tab_bar.dart';
import '../views/witness_impeachment_tab_view.dart';
import '../views/leading_question_deck_tab_view.dart';

class TrialExaminationStudioScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const TrialExaminationStudioScreen({
    super.key,
    this.caseId = 'UP-CR-2026-PW101',
    this.accusedName = 'अभियुक्त (Accused)',
    this.policeStation = 'कोतवाली नगर',
    this.district = 'लखनऊ',
  });

  @override
  ConsumerState<TrialExaminationStudioScreen> createState() => _TrialExaminationStudioScreenState();
}

class _TrialExaminationStudioScreenState extends ConsumerState<TrialExaminationStudioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        titleKey: 'nav_trial_studio',
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
                label: AppStrings.tr(ref, 'mod_witness_grid'),
                icon: Icons.compare_arrows_rounded,
                badgeText: 'Sec 148 BSA',
              ),
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_cross_exam'),
                icon: Icons.style_outlined,
                badgeText: 'Sec 147 BSA',
              ),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WitnessImpeachmentTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                LeadingQuestionDeckTabView(
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

