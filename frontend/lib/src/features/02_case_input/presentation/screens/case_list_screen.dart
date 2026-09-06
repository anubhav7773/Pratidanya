import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/services/activity_service.dart';
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
  String _selectedFilter = 'date'; // 'date', 'court', 'custody'
  bool _showSearchInput = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(caseListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: casesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('डेटा लोड करने में त्रुटि: $err', textAlign: TextAlign.center),
            ),
          ),
          data: (cases) {
            final now = DateTime.now();
            final todayHearingsCount = cases.where((c) {
              if (c.nextHearingDate == null) return false;
              final d = c.nextHearingDate!;
              return d.year == now.year && d.month == now.month && d.day == now.day;
            }).length;

            final judicialCustodyCount = cases
                .where((c) => c.accusedCustodyStatus == 'JUDICIAL_CUSTODY')
                .length;

            final totalCases = cases.length;

            ActivityService.logActivity(
              activityType: 'DOCKET_VIEWED',
              details: {
                'total_cases': totalCases,
                'today_hearings': todayHearingsCount,
                'judicial_custody': judicialCustodyCount,
              },
            );

            return Column(
              children: [
                // Top App Header: Court Navy with Action Bar & Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1C32),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu_open, color: Color(0xFFD6E3FF)),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 4),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'सक्रिय आपराधिक डॉकेट',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFAF8FF),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    'जिला एवं सत्र न्यायालय (District & Sessions Court)',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB9C7E4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search, color: Color(0xFFD6E3FF)),
                                onPressed: () {
                                  setState(() => _showSearchInput = !_showSearchInput);
                                },
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFFD6E3FF)),
                                    onPressed: () {},
                                  ),
                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: StitchColors.alertCrimson,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune, color: Color(0xFFD6E3FF)),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_showSearchInput) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => ref.read(caseSearchQueryProvider.notifier).state = val,
                          style: const TextStyle(color: Colors.black, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'मु.अ.सं. या अभियुक्त का नाम खोजें...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(caseSearchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Quick Stats Pill Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'कुल सक्रिय वाद',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB9C7E4)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalCases',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4F1B2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'आज की पेशी',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF24703E)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    todayHearingsCount.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F6C3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDBD1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'न्यायिक अभिरक्षा',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF842503)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    judicialCustodyCount.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3A0A00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filter & Sort Quick Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildFilterTab(
                            id: 'date',
                            label: 'तारीख वार',
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterTab(
                            id: 'court',
                            label: 'न्यायालय वार',
                            icon: Icons.gavel,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterTab(
                            id: 'custody',
                            label: 'जेल अभिरक्षा',
                            icon: Icons.lock_outline,
                          ),
                        ],
                      ),
                      Text(
                        '$totalCases परिणाम',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF75777E), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Case List & Sponsored Banner
                Expanded(
                  child: cases.isEmpty
                      ? Center(
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
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(caseListProvider),
                          child: ListView.builder(
                            itemCount: cases.length + 1, // +1 for sponsored banner
                            padding: const EdgeInsets.only(bottom: 80.0),
                            itemBuilder: (context, index) {
                              if (index == cases.length) {
                                // Inline Native Sponsored Banner
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFDAE2FD)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E7FF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'प्रायोजित • विधिक शोध',
                                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF44474D)),
                                            ),
                                          ),
                                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF75777E)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D1C32),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.menu_book, color: Color(0xFFD6E3FF), size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'AIR / सुप्रीम कोर्ट केस लॉज़ सब्सक्रिप्शन',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'जिला न्यायालय अधिवक्ताओं के लिए नवीन BNS, BNSS व BSA कमेंट्री सहित 40% विशेष रियायत।',
                                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF44474D), height: 1.3),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'बार काउंसिल सत्यापित प्रदाता',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F6C3A)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0D1C32),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onPressed: () {
                                              ActivityService.logActivity(
                                                activityType: 'AIR_LEGAL_PORTAL_OPENED',
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('AIR विधिक शोध पोर्टल खोला जा रहा है...')),
                                              );
                                            },
                                            child: const Text('विस्तार देखें', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final c = cases[index];
                              return CaseCard(
                                criminalCase: c,
                                onTap: () {
                                  ActivityService.logActivity(
                                    activityType: 'DRAFT_STUDIO_NAVIGATED',
                                    details: {
                                      'case_id': c.id,
                                      'fir_number': c.firNumber,
                                      'district': c.district,
                                    },
                                  );
                                  context.push('/cases/${c.id}/draft-studio');
                                },
                                onArchive: () async {
                                  await ref.read(caseFormControllerProvider.notifier).archiveCase(c.id);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D1C32),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('+ नया केस दर्ज करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        onPressed: () {
          if (widget.onNewCasePressed != null) {
            widget.onNewCasePressed!();
          } else {
            context.push('/cases/new');
          }
        },
      ),
    );
  }

  Widget _buildFilterTab({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1C32) : const Color(0xFFEAEDFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF44474D)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF44474D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
