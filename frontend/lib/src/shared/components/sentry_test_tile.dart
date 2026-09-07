import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryTestTile extends StatelessWidget {
  const SentryTestTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      child: ExpansionTile(
        leading: const Icon(Icons.bug_report, color: Colors.purple),
        title: const Text('Sentry Telemetry Diagnostics'),
        subtitle: const Text('Test crash reporting & layout overflow capture'),
        children: [
          ListTile(
            title: const Text('Trigger Test Exception'),
            subtitle: const Text('Throws StateError and reports to Sentry'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () async {
              try {
                throw StateError('Pratidnya Diagnostic: Sentry Pipeline Verified (Org: asiverticals)');
              } catch (exception, stackTrace) {
                await Sentry.captureException(exception, stackTrace: stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test exception sent to Sentry dashboard!')),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('Simulate Pixel Break (RenderFlex Overflow)'),
            subtitle: const Text('Forces layout overflow to trigger OverflowErrorReporter'),
            trailing: const Icon(Icons.view_compact_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => Scaffold(
                    appBar: AppBar(title: const Text('Pixel Overflow Simulator')),
                    body: const SizedBox(
                      width: 100, // Constrained small width
                      child: Row(
                        children: [
                          Text('यह एक बहुत लंबा वाक्य है जो 100 पिक्सल की स्क्रीन चौड़ाई में कभी फिट नहीं होगा और ओवरफ्लो ट्रिगर करेगा।'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
