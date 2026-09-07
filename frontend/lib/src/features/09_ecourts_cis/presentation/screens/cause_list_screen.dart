import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';
import '../../data/ecourts_repository.dart';
import '../../domain/ecourts_models.dart';

class CauseListScreen extends ConsumerStatefulWidget {
  const CauseListScreen({super.key});

  @override
  ConsumerState<CauseListScreen> createState() => _CauseListScreenState();
}

class _CauseListScreenState extends ConsumerState<CauseListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DailyCauseList? _causeList;
  String _selectedFilter = 'ALL'; // ALL, MY_CASES, CALLED_OUT, BAIL
  int _selectedDayOffset = 0; // 0 = Today, 1 = Tomorrow

  @override
  void initState() {
    super.initState();
    _loadCauseList();
  }

  Future<void> _loadCauseList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(ecourtsRepositoryProvider);
      final profile = ref.read(currentAdvocateProfileProvider).valueOrNull;
      final barNumber = profile?.barCouncilNumber;


      final targetDate = DateTime.now()
          .add(Duration(days: _selectedDayOffset))
          .toIso8601String()
          .split('T')
          .first;

      final data = await repo.fetchDailyCauseList(
        district: 'Lucknow',
        targetDate: targetDate,
        advocateBarNumber: barNumber ?? 'UP/1234/2018',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _causeList = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  List<CauseListEntry> _getFilteredEntries() {
    if (_causeList == null) return [];
    return _causeList!.entries.where((entry) {
      if (_selectedFilter == 'MY_CASES') return entry.isMyCase;
      if (_selectedFilter == 'CALLED_OUT') return entry.listingStatus == 'CALLED_OUT';
      if (_selectedFilter == 'BAIL') {
        return entry.stageOfHearing.contains('जमानत') || entry.caseNumber.contains('Bail');
      }
      return true;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CALLED_OUT':
        return const Color(0xFF15803D);
      case 'ORDER_RESERVED':
        return const Color(0xFF7C3AED);
      case 'PASSOVER':
        return const Color(0xFFD97706);
      case 'ADJOURNED':
        return const Color(0xFF64748B);
      case 'LISTED_TODAY':
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredEntries();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1C32),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/cases');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'दैनिक कॉज लिस्ट',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F6C3A),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: const Text(
                    'CIS 3.2 LIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),

            Text(
              _causeList != null
                  ? '${_causeList!.courtComplex} • ${_causeList!.courtRoom}'
                  : 'जिला एवं सत्र न्यायालय • कॉज लिस्ट बोर्ड',
              style: const TextStyle(fontSize: 11, color: Color(0xFFB9C7E4)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'CIS 3.2 से रिफ्रेश करें',
            onPressed: _loadCauseList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Tabs (Today vs Tomorrow)
          Container(
            color: const Color(0xFF0D1C32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildDayTab(
                    label: 'आज की सूची (Today)',
                    dayOffset: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDayTab(
                    label: 'कल की सूची (Tomorrow)',
                    dayOffset: 1,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'सभी वाद (${_causeList?.totalListed ?? 0})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('MY_CASES', 'मेरे चैंबर के वाद', icon: Icons.person_pin),
                  const SizedBox(width: 8),
                  _buildFilterChip('CALLED_OUT', 'पुकार हुई (Live)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('BAIL', 'जमानत अर्जियां'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0D1C32)),
                        SizedBox(height: 16),
                        Text(
                          'ई-कोर्ट्स सेवा (CIS 3.2) से कॉज लिस्ट लोड हो रही है...',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: StitchColors.alertCrimson),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadCauseList,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1C32)),
                                child: const Text('पुनः प्रयास करें', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_busy, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                const Text(
                                  'इस फ़िल्टर में कोई वाद सूचीबद्ध नहीं है।',
                                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => setState(() => _selectedFilter = 'ALL'),
                                  child: const Text('सभी वाद देखें'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _buildCauseListCard(filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab({required String label, required int dayOffset}) {
    final isSelected = _selectedDayOffset == dayOffset;
    return InkWell(
      onTap: () {
        if (_selectedDayOffset != dayOffset) {
          setState(() => _selectedDayOffset = dayOffset);
          _loadCauseList();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF334155),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {IconData? icon}) {
    final isSelected = _selectedFilter == filterKey;
    return FilterChip(
      avatar: icon != null
          ? Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF0D1C32))
          : null,
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: const Color(0xFF0D1C32),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
    );
  }

  Widget _buildCauseListCard(CauseListEntry entry) {
    final statusColor = _getStatusColor(entry.listingStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isMyCase ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: entry.isMyCase ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Item # + Room + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1C32),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'क्रम #${entry.itemNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.courtRoom,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(

                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.statusLabelHi,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Case Title & CNR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.caseNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1C32),
                  ),
                ),
              ),
              if (entry.isMyCase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: const Text(
                    'मेरा वाद',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'CNR: ${CnrValidator.format(entry.cnrNumber)} • ${entry.firDetails}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const Divider(height: 16),

          // Litigants (वादी बनाम प्रतिवादी)
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${entry.applicantName} बनाम ${entry.oppositeParty}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Advocates (कौंसिल)
          Text(
            'प्रार्थी अधिवक्ता: ${entry.advocateForApplicant}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
          Text(
            'विपक्षी: ${entry.advocateForOpposite}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          // Stage & Sections
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'कार्यवाही: ${entry.stageOfHearing}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                Text(
                  entry.underSections.join(', '),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
