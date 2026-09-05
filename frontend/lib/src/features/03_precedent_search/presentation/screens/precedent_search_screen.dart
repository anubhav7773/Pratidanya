import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/precedent_controller.dart';
import '../widgets/precedent_citation_card.dart';
import '../widgets/precedent_abstain_widget.dart';

class PrecedentSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final List<String>? initialSections;

  const PrecedentSearchScreen({
    super.key,
    this.initialQuery,
    this.initialSections,
  });

  @override
  ConsumerState<PrecedentSearchScreen> createState() => _PrecedentSearchScreenState();
}

class _PrecedentSearchScreenState extends ConsumerState<PrecedentSearchScreen> {
  final _queryController = TextEditingController(text: 'धारा 307 भा.दं.वि. प्राणघातक आशय चोट की गंभीरता');
  final List<String> _selectedSections = [];

  final List<String> _filterChips = [
    'धारा 307 भा.दं.वि. / 109 BNS',
    'उच्चतम न्यायालय (SC)',
    'इलाहाबाद उच्च न्यायालय',
    'जमानत मिसालें (Bail)',
    'अंतिम 5 वर्ष',
  ];

  String _activeChip = 'धारा 307 भा.दं.वि. / 109 BNS';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _queryController.text = widget.initialQuery!;
    }
    if (widget.initialSections != null) {
      _selectedSections.addAll(widget.initialSections!);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    final query = _queryController.text.trim();
    if (query.isNotEmpty) {
      ref.read(precedentSearchControllerProvider.notifier).executeSearch(
            query: query,
            sections: _selectedSections,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(precedentSearchControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Header Context
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF131B2E)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEAEDFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA4F1B2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 7, color: Color(0xFF1F6C3A)),
                                SizedBox(width: 4),
                                Text(
                                  'ई-कोर्ट लाइव',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF24703E)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.tune, color: Color(0xFF131B2E)),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEAEDFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'कानूनी मिसाल खोज (Precedent Search)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'सर्वोच्च न्यायालय एवं उच्च न्यायालय नजीरें • आपराधिक विधि प्रकोष्ठ',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF44474D)),
                  ),
                ],
              ),
            ),

            // Search Field (52px height) & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC5C6CD)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Color(0xFF75777E), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            style: const TextStyle(fontSize: 13.5, color: Color(0xFF131B2E)),
                            decoration: const InputDecoration(
                              hintText: 'तथ्य या विधिक प्रश्न दर्ज करें...',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF75777E)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _triggerSearch(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, size: 20, color: Color(0xFF44474D)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('वॉइस सर्च सक्रिय हो रहा है...')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Color(0xFF75777E)),
                          onPressed: () {
                            _queryController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterChips.map((chip) {
                        final isSelected = _activeChip == chip;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (chip.contains('SC')) const Icon(Icons.gavel, size: 14, color: Color(0xFF1F6C3A)),
                                if (chip.contains('SC')) const SizedBox(width: 4),
                                Text(chip, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.close, size: 14),
                                ],
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0D1C32),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF131B2E)),
                            side: BorderSide(color: isSelected ? const Color(0xFF0D1C32) : const Color(0xFFEAEDFF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (val) {
                              setState(() => _activeChip = val ? chip : '');
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Precedent Stream
            Expanded(
              child: searchAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('खोज त्रुटि: $err', textAlign: TextAlign.center, style: const TextStyle(color: StitchColors.alertCrimson)),
                  ),
                ),
                data: (searchState) {
                  if (!searchState.hasSearched) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          const Text(
                            'केस के तथ्य या विधिक प्रश्न दर्ज कर खोज प्रारंभ करें।',
                            style: TextStyle(color: StitchColors.textSecondary, fontSize: 13.5),
                          ),
                        ],
                      ),
                    );
                  }

                  if (searchState.results.isEmpty) {
                    return PrecedentAbstainWidget(
                      queryTerm: searchState.lastQuery,
                      onModifyQuery: () {
                        _queryController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _queryController.text.length,
                        );
                      },
                    );
                  }

                  return Column(
                    children: [
                      // Results Count & Status Pill
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, size: 16, color: Color(0xFF1F6C3A)),
                                const SizedBox(width: 6),
                                Text(
                                  'प्राप्त परिणाम: ${searchState.results.length} प्रमाणित मिसालें',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDBD1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '1 विधिक चेतावनी',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF842503)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: searchState.results.length,
                          padding: const EdgeInsets.only(bottom: 24.0),
                          itemBuilder: (context, index) {
                            final citation = searchState.results[index];
                            return PrecedentCitationCard(
                              citation: citation,
                              onVerificationChanged: (val) {
                                ref.read(precedentSearchControllerProvider.notifier).toggleVerification(
                                      citation.citationId,
                                      val ?? false,
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom Statutory Notice Footer
            Container(
              padding: const EdgeInsets.all(12.0),
              color: const Color(0xFFF2F3FF),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF1F6C3A)),
                  SizedBox(width: 6),
                  Text(
                    '256-bit ई-कोर्ट एवं बार काउंसिल सत्यापित विधि डेटाबेस',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF44474D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
