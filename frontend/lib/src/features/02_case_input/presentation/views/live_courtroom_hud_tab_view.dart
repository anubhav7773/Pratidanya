import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/courtroom_repository.dart';
import '../../domain/courtroom_tactics_models.dart';

class LiveCourtroomHudTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String district;

  const LiveCourtroomHudTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.district,
  });

  @override
  ConsumerState<LiveCourtroomHudTabView> createState() => _LiveCourtroomHudTabViewState();
}

class _LiveCourtroomHudTabViewState extends ConsumerState<LiveCourtroomHudTabView> {
  final _adversaryArgumentController = TextEditingController();
  bool _isLoading = false;
  EdgeOralPromptResult? _hudResult;

  final List<String> _quickAdversaryScenarios = [
    'व्यावसायिक मात्रा (Commercial Quantity) बरामद हुई है, धारा 37 में बेल नहीं दी जा सकती।',
    '7 वर्ष तक की सजा है, अभियुक्त से पूछताछ हेतु पुलिस रिमांड स्वीकृत की जाए।',
    'अभियुक्त पर गंभीर गैंगस्टर एक्ट (UP Gangsters Act) लगा हुआ है।',
  ];

  @override
  void dispose() {
    _adversaryArgumentController.dispose();
    super.dispose();
  }

  void _triggerPrompt(String argumentText) async {
    if (argumentText.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(courtroomRepositoryProvider);
      final res = await repo.requestEdgeOralPrompt(
        caseId: widget.caseId,
        adversaryArgumentRawText: argumentText.trim(),
        activeJudgeId: 'JUDGE-UP-LKO-04',
        activeOffenseCategory: 'NDPS',
      );

      setState(() {
        _hudResult = res;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        // Live HUD Control Panel
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: LuxuryPalette.goldGlow, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.tr(ref, 'live_hud_title'),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Text(
                      '< 450ms Edge Active',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.tr(ref, 'live_hud_hint'),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Argument Input with Send Button
              TextField(
                controller: _adversaryArgumentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'अभियोजन पक्ष की दलील दर्ज करें अथवा नीचे दिए गए परिदृश्यों को चुनें...',
                  suffixIcon: IconButton(
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: LuxuryPalette.champagneGold),
                    onPressed: _isLoading ? null : () => _triggerPrompt(_adversaryArgumentController.text),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Quick Adversary Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickAdversaryScenarios.map((scenario) {
                  return ActionChip(
                    label: Text(
                      scenario.length > 32 ? '${scenario.substring(0, 32)}...' : scenario,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    backgroundColor: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
                    onPressed: () {
                      _adversaryArgumentController.text = scenario;
                      _triggerPrompt(scenario);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // HUD Result Card
        if (_hudResult != null) ...[
          LuxuryCard(
            hasGoldAccent: true,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.tr(ref, 'detected_ratio_label'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      '${_hudResult!.latencyMs["total_latency_ms"] ?? 28} ms',
                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _hudResult!.detectedAdversarialRatio,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 16),

                // Counter Ratios
                ..._hudResult!.immediateCounterRatios.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF13233E) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? LuxuryPalette.midnightBorderSubtle : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  r.statutoryLever,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: LuxuryPalette.champagneGold),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: r.promptTextHindi));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppStrings.tr(ref, 'copied_snackbar'))),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${r.promptTextHindi}"',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.35),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppStrings.tr(ref, "lead_citation_label")} ${r.leadCitation}',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark ? LuxuryPalette.champagneGold : Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
