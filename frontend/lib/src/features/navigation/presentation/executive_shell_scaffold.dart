import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/components/executive_dock_navigation_bar.dart';
import '../../02_case_input/presentation/screens/dashboard_screen.dart';
import '../../02_case_input/presentation/screens/pre_trial_remand_hub_screen.dart';
import '../../02_case_input/presentation/screens/electronic_evidence_audit_screen.dart';
import '../../02_case_input/presentation/screens/regional_acts_audit_screen.dart';
import '../../02_case_input/presentation/widgets/live_courtroom_hud_widget.dart';

class ExecutiveShellScaffold extends ConsumerWidget {
  const ExecutiveShellScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTabIndex = ref.watch(executiveNavIndexProvider);

    final List<Widget> pages = [
      DashboardScreen(
        onAddNewCase: () {
          // Triggers case registration
        },
      ),
      // 1. Dedicated Pre-Trial & Remand Defense Hub (Pillar A)
      const PreTrialRemandHubScreen(),
      // 2. Forensics & Evidence Vault (Pillar B)
      const ElectronicEvidenceAuditScreen(
        caseId: 'ACTIVE-BSA-DOCKET',
        accusedName: 'अभियुक्त',
        policeStation: 'कोतवाली',
        district: 'लखनऊ',
      ),
      // 3. Trial Examination Studio (Pillar C)
      const RegionalActsAuditScreen(
        caseId: 'ACTIVE-TRIAL-DOCKET',
        accusedName: 'अभियुक्त',
        policeStation: 'कोतवाली',
        district: 'लखनऊ',
      ),
      // 4. Regional Acts & Tactical Courtroom HUD (Pillars D & E)
      const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: LiveCourtroomHUDWidget(
              caseId: 'LIVE-COURTROOM-CASE',
              accusedName: 'अभियुक्त',
              district: 'लखनऊ',
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: activeTabIndex,
        children: pages,
      ),
      bottomNavigationBar: const ExecutiveDockNavigationBar(
        activeAlertCount: 2,
      ),
    );
  }
}
