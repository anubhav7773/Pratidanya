import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/config/app_environment.dart';
import 'src/features/billing/data/admob_service.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Statutory Environment Security Assertion
  try {
    AppEnvironment.validateEnvironmentSecurity();
  } catch (e) {
    debugPrint('Environment security check note: $e');
  }

  // 2. Initialize Firebase Core
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // 3. Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppEnvironment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 2,
      ),
    );
  } catch (e) {
    debugPrint('Supabase initialization note: $e');
  }

  // 4. Initialize Google Mobile Ads SDK
  try {
    await AdMobService.initialize();
  } catch (e) {
    debugPrint('AdMob initialization note: $e');
  }

  runApp(
    const ProviderScope(
      child: PratidnyaApplication(),
    ),
  );
}
