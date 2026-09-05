import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/config/app_environment.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Statutory Environment Security Assertion
  AppEnvironment.validateEnvironmentSecurity();

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

  runApp(
    const ProviderScope(
      child: PratidnyaApplication(),
    ),
  );
}
