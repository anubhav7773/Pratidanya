import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
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
  final _queryController = TextEditingController();
  final List<String> _selectedSections = [];

  final List<String> _availableSections = [
    '379',
    '411',
    '303 BNS',
    '317(2) BNS',
    '420',
    '302',
    '307',
  ];

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
      appBar: AppBar(
        title: const Text('विधिक मिसाल अनुसंधान (Precedent Search)'),
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'तथ्य या विधिक तर्क दर्ज करें (उदा. बिना स्वतंत्र गवाह जब्ती)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(color: StitchColors.borderSubtle),
                          ),
                        ),
                        onSubmitted: (_) => _triggerSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchColors.courtNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                      ),
                      onPressed: _triggerSearch,
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableSections.map((sec) {
                      final isSelected = _selectedSections.contains(sec);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text('धारा $sec', style: const TextStyle(fontSize: 11.5)),
                          selected: isSelected,
                          selectedColor: StitchColors.courtNavy.withValues(alpha: 0.12),
                          checkmarkColor: StitchColors.courtNavy,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedSections.add(sec);
                              } else {
                                _selectedSections.remove(sec);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
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
                  return PrecedentAbstainWidget(queryTerm: searchState.lastQuery);
                }

                return ListView.builder(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
