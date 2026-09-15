import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/chamber_http_client.dart';

final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger(ref.read(chamberHttpClientProvider));
});

class ActivityLogger {
  final ChamberHttpClient _client;

  ActivityLogger(this._client);

  Future<void> logEvent({
    required String eventType, // 'APP_LAUNCH', 'LOGIN', 'LOGOUT', 'TAB_SWITCH', 'MODULE_CLICK', 'PETITION_EXPORT'
    required String moduleName,
    Map<String, dynamic> details = const {},
    String? caseId,
  }) async {
    try {
      await _client.post(
        path: '/api/v1/telemetry/log-activity',
        actionName: 'CLIENT_LOG_$eventType',
        caseId: caseId,
        body: {
          'event_type': eventType,
          'module_name': moduleName,
          'action_details': details,
          'case_id': caseId,
          'client_timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {
      // Telemetry errors should never interrupt user workflows
    }
  }
}
