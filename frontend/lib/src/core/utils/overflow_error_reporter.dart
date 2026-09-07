import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class OverflowErrorReporter {
  /// Intercepts Flutter framework errors specifically targeting RenderFlex overflows
  static void initialize() {
    final originalOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) async {
      // 1. Check if the error is a RenderFlex overflow (Yellow-Black stripes / Pixel Break)
      final bool isOverflow = details.exceptionAsString().contains('A RenderFlex overflowed by') ||
          details.exceptionAsString().contains('RenderFlex overflowed');

      if (isOverflow) {
        debugPrint('[Pratidnya Layout Guard] ⚠️ PIXEL OVERFLOW DETECTED: ${details.exceptionAsString()}');

        await Sentry.captureEvent(
          SentryEvent(
            level: SentryLevel.warning,
            message: SentryMessage('UI Layout Pixel Overflow: ${details.summary}'),
            throwable: details.exception,
            tags: {
              'error_type': 'RenderFlex_Overflow',
              'library': details.library ?? 'rendering',
            },
            // ignore: deprecated_member_use
            extra: {
              'context': details.context?.toString(),
              'informationCollector': details.informationCollector?.call().map((e) => e.toString()).toList(),
            },
          ),
          stackTrace: details.stack,
        );
      }

      // Forward to default/original handler so standard logs continue
      if (originalOnError != null) {
        originalOnError(details);
      }
    };
  }
}
