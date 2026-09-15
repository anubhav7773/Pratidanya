import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/trial_repository.dart';
import '../../domain/leading_question_models.dart';
import '../widgets/cross_exam_card_deck_widget.dart';

class LeadingQuestionDeckTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const LeadingQuestionDeckTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<LeadingQuestionDeckTabView> createState() => _LeadingQuestionDeckTabViewState();
}

class _LeadingQuestionDeckTabViewState extends ConsumerState<LeadingQuestionDeckTabView> {
  final _witnessNameController = TextEditingController(text: 'राम लखन (पंच साक्षी)');
  String _defenseTheory = 'PLANTED_RECOVERY_STOCK_WITNESS';

  final Map<String, String> _defenseTheories = {
    'PLANTED_RECOVERY_STOCK_WITNESS': 'फर्जी बरामदगी व स्टॉक गवाह (Planted Recovery / Stock Witness)',
    'ALIBI_AND_ABSENCE': 'अन्यत्रता का साक्ष्य (Alibi & Physical Absence)',
    'CONSENSUAL_RELATION_SEC_69_BNS': 'सहमतिजन्य संबंध व कपट का अभाव (Sec 69 BNS / 376 IPC)',
    'MISTAKEN_IDENTITY_TIP_FAILURE': 'गलत पहचान व पहचान परेड की शून्यता (TIP Failure)',
  };

  bool _isLoading = false;
  LeadingQuestionResult? _deckResult;

  @override
  void dispose() {
    _witnessNameController.dispose();
    super.dispose();
  }

  void _runGeneration() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trialRepositoryProvider);
      final res = await repo.generateCrossQuestions(
        caseId: widget.caseId,
        witnessName: _witnessNameController.text.trim(),
        witnessRole: 'PANCH_WITNESS_SEIZURE',
        defenseTheory: _defenseTheory,
        caseFacts: {
          'recovery_place': 'खुला अरहर का खेत',
          'witness_residence_distance_km': 14,
          'prior_appearances_count': 4,
          'weapon_type': 'अवैध 315 बोर तमंचा',
          'prosecutrix_age': 23,
          'relationship_duration_months': 24,
        },
        accusedName: widget.accusedName,
        policeStation: widget.policeStation,
        district: widget.district,
      );

      setState(() {
        _deckResult = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.tr(ref, "error_prefix")}$e'),
            backgroundColor: LuxuryPalette.rubyAlert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'cross_exam_deck_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _witnessNameController,
                decoration: const InputDecoration(labelText: 'साक्षी का नाम व भूमिका (Witness Name)'),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _defenseTheory,
                isExpanded: true,
                decoration: InputDecoration(labelText: AppStrings.tr(ref, 'defense_theory_label')),
                items: _defenseTheories.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _defenseTheory = val ?? _defenseTheory),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxuryPalette.courtNavy,
                    foregroundColor: LuxuryPalette.lightSurface,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.style_outlined, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : 'सूचक प्रश्न डेक (Leading Question Deck) बनाएं'),
                  onPressed: _isLoading ? null : _runGeneration,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_deckResult != null) ...[
          CrossExamCardDeckWidget(result: _deckResult!),
        ],
      ],
    );
  }
}
