import 'package:flutter/material.dart';

class PrecedentAbstainWidget extends StatelessWidget {
  final String queryTerm;
  final VoidCallback? onModifyQuery;

  const PrecedentAbstainWidget({super.key, required this.queryTerm, this.onModifyQuery});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDBD1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Line
              Container(
                width: 6,
                color: const Color(0xFF842503),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB59F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gavel, color: Color(0xFF3A0A00), size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shield, size: 14, color: Color(0xFF842503)),
                                    SizedBox(width: 4),
                                    Text(
                                      'शून्य भ्रांति सिद्धांत (Zero Hallucination Guarantee)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF842503),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'कोई पुष्ट कानूनी मिसाल (Precedent) नहीं मिली',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3A0A00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Query Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.manage_search, size: 16, color: Color(0xFF75777E)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'खोज प्रश्न: "$queryTerm"',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF131B2E)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Advisory Body
                      const Text(
                        'विधिक एआई सुरक्षा नियम 3 के अंतर्गत, इस विशिष्ट तथ्य पर किसी उच्च या सर्वोच्च न्यायालय की प्रमाणित विधिक नजीर उपलब्ध नहीं है। न्यूनतम 65% प्रासंगिक निर्णय उपलब्ध नहीं है (BCI Rule 5)। काल्पनिक या अपुष्ट केस उद्धरण प्रस्तुत करना विधि व्यवसाय की मर्यादा के प्रतिकूल है।',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF3A0A00), height: 1.4),
                      ),
                      const SizedBox(height: 10),

                      // Guidance Callout
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB59F).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFF3A0A00)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'अधिवक्ता परामर्श: कृपया जिला विधि पुस्तकालय या आधिकारिक मैनुअल लॉ रिपोर्टर (SCR / AIR) से स्वयं शोध करें। न्यायालय के समक्ष किसी अनसत्यापित केस का हवाला न दें।',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF3A0A00), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A0A00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text('मैन्युअल केस रिपोर्टर खोलें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ई-कोर्ट्स आधिकारिक रिपोर्टर संदर्भ खोला जा रहा है...')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (onModifyQuery != null)
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3A0A00),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('शोध प्रश्न संशोधित करें', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            onPressed: onModifyQuery,
                          ),
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
