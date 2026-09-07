import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:ui';
import 'src/core/config/app_environment.dart';
import 'src/core/services/activity_service.dart';
import 'src/core/utils/overflow_error_reporter.dart';
import 'src/features/billing/data/admob_service.dart';
import 'src/shared/components/custom_error_screen.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Production Error Boundary & Telemetry
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ActivityService.logActivity(
      activityType: 'CRITICAL_FRAMEWORK_ERROR',
      details: {
        'exception': details.exceptionAsString(),
        'library': details.library ?? 'flutter_framework',
      },
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ActivityService.logActivity(
      activityType: 'CRITICAL_ISOLATE_ERROR',
      details: {'error': error.toString()},
    );
    Sentry.captureException(error, stackTrace: stack);
    return true; // prevent application crash
  };

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return CustomErrorScreen(errorDetails: errorDetails);
  };

  // Initialize Sentry SDK for Org: asiverticals | Project: pratidnya
  await SentryFlutter.init(
    (options) {
      // DSN pass via compile-time argument (--dart-define=SENTRY_DSN=...) or fallback
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: 'https://3edaa68c2f469fcdc88b178bbe53a72c@o4511946639015936.ingest.us.sentry.io/4512042881056768',
      );

      // Environment & Release Tracking
      options.environment = AppEnvironment.appEnv;
      options.release = 'pratidnya@1.0.0+1';

      // Capture screenshots and view hierarchy when pixel overflows or crashes occur
      options.attachScreenshot = true;
      // ignore: experimental_member_use
      options.attachViewHierarchy = true;

      // Report framework layout overflows and silent errors
      options.reportSilentFlutterErrors = true;

      // Tracing and Profiling sample rates
      options.tracesSampleRate = 1.0;
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;

      // Enable Automatic User Interaction Tracing (button taps, scroll bottlenecks)
      options.enableUserInteractionTracing = true;
    },
    appRunner: () async {
      // 0. Initialize Layout Overflow (Pixel Break) Interceptor after Sentry init
      OverflowErrorReporter.initialize();

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

      // 5. Silently warm up Render microservice in background so container is hot
      AppEnvironment.warmupBackend();
    },
  );
}
