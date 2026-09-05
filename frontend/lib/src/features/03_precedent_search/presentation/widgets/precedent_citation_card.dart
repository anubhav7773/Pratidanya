import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/precedent_citation.dart';

class PrecedentCitationCard extends StatelessWidget {
  final PrecedentCitation citation;
  final ValueChanged<bool?> onVerificationChanged;

  const PrecedentCitationCard({
    super.key,
    required this.citation,
    required this.onVerificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scaled = citation.similarityScore * 100;
    final accuracyPercent = (scaled % 1 == 0) ? scaled.toStringAsFixed(0) : scaled.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFEAEDFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Colored Indicator Strip
              Container(
                width: 6,
                color: const Color(0xFF1F6C3A),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Meta & Neutral Citation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NEUTRAL CITATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF75777E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                citation.citationId,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF131B2E),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA4F1B2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 13, color: Color(0xFF1F6C3A)),
                                const SizedBox(width: 4),
                                Text(
                                  'सटीकता: $accuracyPercent%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF24703E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Litigants & Bench
                      Text(
                        citation.caseTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        citation.courtName,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF44474D)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Color(0xFF75777E)),
                          const SizedBox(width: 4),
                          Text(
                            'निर्णय: ${citation.judgmentDate}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF75777E)),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Color(0xFF75777E))),
                          const SizedBox(width: 8),
                          const Text(
                            'निर्णायक नजीर (Binding)',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Legal Ratio Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.balance, size: 15, color: Color(0xFF0D1C32)),
                                SizedBox(width: 6),
                                Text(
                                  'विधि का सार (Legal Ratio):',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              citation.headnoteHindi,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF131B2E), height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quoted Para Block
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAE2FD).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.format_quote, size: 14, color: Color(0xFF75777E)),
                                SizedBox(width: 4),
                                Text(
                                  'माननीय पीठ का आधिकारिक उद्धरण:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF75777E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'पैरा ${citation.paragraphNumber ?? "14"}: "${citation.verbatimText}"',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF131B2E),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Actions Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ई-कोर्ट रिकॉर्ड ${citation.citationId} खोला जा रहा है...')),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'सत्यापित स्रोत रिकॉर्ड देखें ↗',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1C32),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.content_copy, size: 18, color: Color(0xFF75777E)),
                                tooltip: 'सार कॉपी करें',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: '${citation.caseTitle}\n${citation.headnoteHindi}'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('मिसाल सार क्लिपबोर्ड पर कॉपी किया गया।')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.bookmark_border, size: 18, color: Color(0xFF75777E)),
                                tooltip: 'बुकमार्क',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('मिसाल बुकमार्क में सुरक्षित की गई।')),
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: citation.isManuallyVerified,
                                    activeColor: const Color(0xFF1F6C3A),
                                    onChanged: onVerificationChanged,
                                  ),
                                  const Text('सत्यापित किया', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
