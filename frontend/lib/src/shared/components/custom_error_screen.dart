import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

/// Production Error Boundary Screen
/// Renders a graceful, dignified recovery interface instead of the red/grey screen of death
class CustomErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorScreen({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1C32).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gavel_rounded, size: 36, color: Color(0xFF0D1C32)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'प्रतिज्ञा विधिक इंटरफ़ेस सूचना',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1C32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'विधिक प्रपत्र रेंडरिंग में तकनीकी रुकावट आई है। अधिवक्ता डेटा पूर्णतः सुरक्षित है।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      errorDetails.exceptionAsString().split('\n').first,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D1C32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('पुनः लोड करें (Reload)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          // Trigger application reassembly / hot reload
                          WidgetsBinding.instance.reassembleApplication();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, size: 14, color: StitchColors.verifiedGreen),
                      SizedBox(width: 6),
                      Text(
                        'DPDP Act 2023 एवं BCI Rule 36 अनुपालित',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
