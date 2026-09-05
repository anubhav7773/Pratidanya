import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../controllers/case_controller.dart';
import '../widgets/case_card.dart';

class CaseListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNewCasePressed;

  const CaseListScreen({super.key, this.onNewCasePressed});

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(caseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('आपराधिक वाद दैनिकी (Case Diary)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(caseListProvider),
            tooltip: 'ताज़ा करें',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: StitchColors.courtNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('नया केस दर्ज करें', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          if (widget.onNewCasePressed != null) {
            widget.onNewCasePressed!();
          } else {
            context.push('/cases/new');
          }
        },
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(caseSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'मु.अ.सं. या अभियुक्त का नाम खोजें...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(caseSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: StitchColors.borderSubtle),
                ),
              ),
            ),
          ),
          Expanded(
            child: casesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('डेटा लोड करने में त्रुटि: $err', textAlign: TextAlign.center),
                ),
              ),
              data: (cases) {
                if (cases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'कोई सक्रिय केस नहीं मिला',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: StitchColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'निचले बटन से नया आपराधिक केस जोड़ें।',
                          style: TextStyle(fontSize: 13, color: StitchColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(caseListProvider),
                  child: ListView.builder(
                    itemCount: cases.length,
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemBuilder: (context, index) {
                      final c = cases[index];
                      return CaseCard(
                        criminalCase: c,
                        onTap: () {
                          // Navigate to 360 Drafting Studio for this case
                          context.push('/cases/${c.id}/draft-studio');
                        },
                        onArchive: () async {
                          await ref.read(caseFormControllerProvider.notifier).archiveCase(c.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
