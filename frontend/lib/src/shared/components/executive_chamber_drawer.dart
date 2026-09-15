import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_language.dart';
import '../../core/telemetry/activity_logger.dart';
import '../../core/theme/luxury_palette.dart';
import 'luxury_card.dart';

// Foundational Core Screens
import '../../features/02_case_input/presentation/screens/case_registration_screen.dart';
import '../../features/03_precedent_search/presentation/screens/precedent_search_screen.dart';
import '../../features/06_high_court/presentation/screens/high_court_appellate_studio_screen.dart';
import '../../features/09_ecourts_cis/presentation/screens/daily_cause_list_screen.dart';
import '../../features/billing/presentation/screens/executive_billing_screen.dart';
import '../../features/10_compliance_audit/presentation/screens/dpdp_compliance_screen.dart';

class ExecutiveChamberDrawer extends ConsumerWidget {
  const ExecutiveChamberDrawer({super.key});

  void _navigateTo(BuildContext context, WidgetRef ref, Widget screen, String screenName) {
    Navigator.of(context).pop(); // Close drawer first

    // Log telemetry to Render console
    ref.read(activityLoggerProvider).logEvent(
      eventType: 'DRAWER_NAVIGATION',
      moduleName: screenName,
      details: {'destination': screen.runtimeType.toString()},
    );

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = ref.watch(appLanguageProvider);

    return Drawer(
      backgroundColor: isDark ? LuxuryPalette.midnightCanvas : LuxuryPalette.offWhiteCanvas,
      child: Column(
        children: [
          // 1. Advocate Chamber Header
          _buildChamberHeader(context, ref, isDark),

          // 2. Navigation Categories
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _buildSectionHeader(
                  currentLang == AppLanguage.hindi ? 'दैनिक वकालत एवं वाद' : 'CORE PRACTICE & DOCKETS',
                ),

                _buildDrawerTile(
                  icon: Icons.add_circle_outline,
                  title: currentLang == AppLanguage.hindi ? 'नया केस दर्ज करें (Voice Intake)' : 'Register New Case (Voice Intake)',
                  subtitle: currentLang == AppLanguage.hindi ? 'हाइब्रिड BNS / IPC वाद डायरी' : 'Hybrid BNS / IPC Case Diary',
                  isDark: isDark,
                  onTap: () => _navigateTo(
                    context,
                    ref,
                    const CaseRegistrationScreen(),
                    'CASE_REGISTRATION',
                  ),
                ),

                _buildDrawerTile(
                  icon: Icons.search_rounded,
                  title: currentLang == AppLanguage.hindi ? 'कानूनी मिसाल खोज (Precedents)' : 'Precedent Research Library',
                  subtitle: currentLang == AppLanguage.hindi ? 'सर्वोच्च व उच्च न्यायालय नजीरें' : 'Supreme Court & HC Citations',
                  isDark: isDark,
                  onTap: () => _navigateTo(
                    context,
                    ref,
                    const PrecedentSearchScreen(),
                    'PRECEDENT_SEARCH',
                  ),
                ),

                _buildDrawerTile(
                  icon: Icons.table_chart_outlined,
                  title: currentLang == AppLanguage.hindi ? 'दैनिक कॉज लिस्ट (CIS 3.2)' : 'Daily Cause List (CIS 3.2)',
                  subtitle: currentLang == AppLanguage.hindi ? 'ई-कोर्ट्स लाइव पुकार व बोर्ड' : 'Live Hearing Call & Stage Board',
                  badge: 'LIVE',
                  isDark: isDark,
                  onTap: () => _navigateTo(
                    context,
                    ref,
                    const DailyCauseListScreen(),
                    'DAILY_CAUSE_LIST',
                  ),
                ),

                const Divider(height: 18),
                _buildSectionHeader(
                  currentLang == AppLanguage.hindi ? 'उच्च न्यायालय व अपीलीय प्रकोष्ठ' : 'APPELLATE & HIGH COURT',
                ),

                _buildDrawerTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: currentLang == AppLanguage.hindi ? 'अपील / पुनरीक्षण मेमो' : 'High Court Appellate Studio',
                  subtitle: currentLang == AppLanguage.hindi ? '1.75" मार्जिन पेपर-बुक एक्सपोर्ट' : '1.75" Left Margin Paper-Book',
                  isDark: isDark,
                  onTap: () => _navigateTo(
                    context,
                    ref,
                    const HighCourtAppellateStudioScreen(),
                    'HIGH_COURT_STUDIO',
                  ),
                ),

                const Divider(height: 18),
                _buildSectionHeader(
                  currentLang == AppLanguage.hindi ? 'चैंबर प्रबंधन व विधिक ऑडिट' : 'CHAMBER COMPLIANCE & PRO',
                ),

                _buildDrawerTile(
                  icon: Icons.workspace_premium_outlined,
                  title: currentLang == AppLanguage.hindi ? 'अधिवक्ता कोटा एवं सदस्यता' : 'Executive Quota & Billing',
                  subtitle: currentLang == AppLanguage.hindi ? 'प्रो योजना व जीएसटी टैक्स इनवॉइस' : 'Pro Plan & GST Tax Invoices',
                  isDark: isDark,
                  onTap: () => _navigateTo(
                    context,
                    ref,
                    const ExecutiveBillingScreen(),
                    'EXECUTIVE_BILLING',
                  ),
                ),

                _buildDrawerTile(
                  icon: Icons.shield_outlined,
                  title: currentLang == AppLanguage.hindi ? 'चैंबर विधिक ऑडिट (DPDP)' : 'Chamber DPDP Act Audit',
                  subtitle: currentLang == AppLanguage.hindi ? 'BCI नियम 36 व डेटा सुरक्षा' : 'BCI Rule 36 & Data Sovereignty',
                  isDark: isDark,
                  onTap: () => _navigateTo(
                    context,
                    ref,
                    const DpdpComplianceScreen(),
                    'DPDP_COMPLIANCE',
                  ),
                ),
              ],
            ),
          ),
        ),

          // 3. Bottom Session Status Card
          _buildBottomChamberStatus(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildChamberHeader(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: isDark ? LuxuryPalette.darkCardGradient : LuxuryPalette.courtHeaderGradient,
        border: const Border(
          bottom: BorderSide(color: LuxuryPalette.champagneGold, width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LuxuryPalette.champagneGold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: LuxuryPalette.champagneGold, width: 1.5),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: LuxuryPalette.champagneGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adv. Anubhav Singh',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'UP/1234/2018 • Lucknow Bench',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              LuxuryBadge(
                label: 'BCI RULE 36 VERIFIED',
                foregroundColor: LuxuryPalette.courtNavy,
                backgroundColor: LuxuryPalette.champagneGold,
                icon: Icons.verified,
              ),
              Text(
                'Chamber Pro Active',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LuxuryPalette.emeraldVerified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: LuxuryPalette.antiqueBronze,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark
                ? LuxuryPalette.midnightElevated
                : LuxuryPalette.lightSurfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder,
            ),
          ),
          child: Icon(icon, size: 18, color: LuxuryPalette.champagneGold),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? LuxuryPalette.darkTextPrimary : LuxuryPalette.courtNavy,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LuxuryPalette.rubyBgLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: LuxuryPalette.rubyAlert, width: 0.8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: LuxuryPalette.rubyAlert,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomChamberStatus(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF091224) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: LuxuryPalette.emeraldVerified,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Render Live Gateway 200 OK',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'v1.2 Executive',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? LuxuryPalette.darkTextMuted : LuxuryPalette.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
