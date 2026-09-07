import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../features/01_onboarding/presentation/controllers/auth_controller.dart';
import '../../features/01_onboarding/presentation/screens/login_screen.dart';
import '../../features/01_onboarding/presentation/screens/dpdp_consent_screen.dart';
import '../../features/01_onboarding/presentation/screens/bar_profile_screen.dart';
import '../../features/02_case_input/presentation/screens/case_list_screen.dart';
import '../../features/02_case_input/presentation/screens/new_case_form_screen.dart';
import '../../features/02_case_input/presentation/screens/ai_section_advisor_screen.dart';
import '../../features/03_precedent_search/presentation/screens/precedent_search_screen.dart';
import '../../features/04_draft_generator/presentation/screens/draft_studio_screen.dart';

import '../../features/05_verify_and_export/presentation/screens/verification_gate_screen.dart';
import '../../features/billing/presentation/screens/paywall_screen.dart';
import '../../features/06_high_court/presentation/screens/high_court_studio_screen.dart';
import '../../features/07_specialized_acts/presentation/screens/ndps_compliance_screen.dart';
import '../../features/07_specialized_acts/presentation/screens/pocso_age_audit_screen.dart';
import '../../features/07_specialized_acts/presentation/screens/scst_appeal_screen.dart';
import '../../features/07_specialized_acts/presentation/screens/ni_act_defense_screen.dart';
import '../../features/09_ecourts_cis/presentation/screens/cause_list_screen.dart';
import '../../features/10_compliance_audit/presentation/screens/chamber_privacy_audit_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
    _ref.listen(authStateStreamProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/cases',
    observers: [
      SentryNavigatorObserver(),
    ],
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) async {
      final currentPath = state.matchedLocation;
      final isLoggingIn = currentPath == '/login';
      final isConsentScreen = currentPath == '/dpdp-consent';
      final isBarEnrollmentScreen = currentPath == '/bar-enrollment';

      User? firebaseUser;
      try {
        if (Firebase.apps.isNotEmpty) {
          firebaseUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        debugPrint('Firebase Auth status check note: $e');
      }

      // Gate 1: Check Authentication
      if (firebaseUser == null) {
        return isLoggingIn ? null : '/login';
      }

      // Query Supabase for Advocate Profile & Consent Metadata using Firebase UID
      try {
        final profileResponse = await supa.Supabase.instance.client
            .from('advocate_profiles')
            .select('dpdp_consent_accepted, bar_council_number')
            .eq('id', firebaseUser.uid)
            .maybeSingle();

        final bool hasConsented = profileResponse?['dpdp_consent_accepted'] == true;
        final String? barNumber = profileResponse?['bar_council_number'];

        // Gate 2: Mandatory DPDP Statutory Consent
        if (!hasConsented) {
          return isConsentScreen ? null : '/dpdp-consent';
        }

        // Gate 3: Advocates Act Enrolled Verification Gate
        if (barNumber == null || barNumber.trim().isEmpty) {
          return isBarEnrollmentScreen ? null : '/bar-enrollment';
        }

        if (isLoggingIn || isConsentScreen || isBarEnrollmentScreen) {
          return '/cases';
        }
      } catch (e) {
        debugPrint('Router check sync note: $e');
        // If an authenticated advocate encounters a query error,
        // navigate them forward to the DPDP onboarding consent screen, never trap on /login
        if (isLoggingIn) {
          return '/dpdp-consent';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dpdp-consent',
        builder: (context, state) => const DpdpConsentScreen(),
      ),
      GoRoute(
        path: '/bar-enrollment',
        builder: (context, state) => const BarProfileScreen(),
      ),
      GoRoute(
        path: '/cases',
        builder: (context, state) => const CaseListScreen(),
      ),
      GoRoute(
        path: '/cases/new',
        builder: (context, state) => const NewCaseFormScreen(),
      ),
      GoRoute(
        path: '/ai-section-advisor',
        builder: (context, state) {
          final facts = state.extra as String?;
          return AiSectionAdvisorScreen(initialFactualMatrix: facts);
        },
      ),
      GoRoute(
        path: '/cases/:id/draft-studio',
        builder: (context, state) {
          final caseId = state.pathParameters['id'] ?? '';
          return DraftStudioScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/cases/:id/verify-gate',
        builder: (context, state) {
          final caseId = state.pathParameters['id'] ?? '';
          return VerificationGateScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/precedent-search',
        builder: (context, state) => const PrecedentSearchScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/high-court',
        builder: (context, state) => const HighCourtStudioScreen(),
      ),
      GoRoute(
        path: '/cases/:id/ndps-compliance',
        builder: (context, state) {
          final caseId = state.pathParameters['id'] ?? '';
          return NdpsComplianceScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/cases/:id/pocso-age-audit',
        builder: (context, state) {
          final caseId = state.pathParameters['id'] ?? '';
          return PocsoAgeAuditScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/cases/:id/scst-appeal',
        builder: (context, state) {
          final caseId = state.pathParameters['id'] ?? '';
          return ScstAppealScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/cases/:id/ni-act-defense',
        builder: (context, state) {
          final caseId = state.pathParameters['id'] ?? '';
          return NiActDefenseScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: '/cause-list',
        builder: (context, state) => const CauseListScreen(),
      ),
      GoRoute(
        path: '/chamber-privacy-audit',
        builder: (context, state) => const ChamberPrivacyAuditScreen(),
      ),
    ],
  );
});

