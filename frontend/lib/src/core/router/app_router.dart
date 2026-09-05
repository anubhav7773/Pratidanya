import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../features/01_onboarding/presentation/screens/login_screen.dart';
import '../../features/01_onboarding/presentation/screens/dpdp_consent_screen.dart';
import '../../features/01_onboarding/presentation/screens/bar_profile_screen.dart';
import '../../features/02_case_input/presentation/screens/case_list_screen.dart';
import '../../features/02_case_input/presentation/screens/new_case_form_screen.dart';
import '../../features/03_precedent_search/presentation/screens/precedent_search_screen.dart';
import '../../features/04_draft_generator/presentation/screens/draft_studio_screen.dart';

import '../../features/05_verify_and_export/presentation/screens/verification_gate_screen.dart';
import '../../features/billing/presentation/screens/paywall_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/cases',
    redirect: (BuildContext context, GoRouterState state) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final currentPath = state.matchedLocation;

      final isLoggingIn = currentPath == '/login';
      final isConsentScreen = currentPath == '/dpdp-consent';
      final isBarEnrollmentScreen = currentPath == '/bar-enrollment';

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
    ],
  );
});
