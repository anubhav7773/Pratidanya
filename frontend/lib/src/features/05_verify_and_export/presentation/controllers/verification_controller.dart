import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerificationGateState {
  final Map<String, bool> verifiedCitations;
  final Map<int, bool> verifiedGrounds;
  final bool statutoryDeclarationAccepted;

  VerificationGateState({
    required this.verifiedCitations,
    required this.verifiedGrounds,
    required this.statutoryDeclarationAccepted,
  });

  bool get isReadyForExport {
    if (!statutoryDeclarationAccepted) return false;
    
    final allCitationsChecked = verifiedCitations.isEmpty || 
        verifiedCitations.values.every((v) => v == true);
    final allGroundsChecked = verifiedGrounds.isEmpty || 
        verifiedGrounds.values.every((v) => v == true);

    return allCitationsChecked && allGroundsChecked;
  }

  int get pendingItemsCount {
    int count = 0;
    count += verifiedCitations.values.where((v) => v == false).length;
    count += verifiedGrounds.values.where((v) => v == false).length;
    if (!statutoryDeclarationAccepted) count += 1;
    return count;
  }
}

class VerificationNotifier extends StateNotifier<VerificationGateState> {
  VerificationNotifier({
    required List<String> citationIds,
    required int groundsCount,
  }) : super(VerificationGateState(
          verifiedCitations: {for (var id in citationIds) id: false},
          verifiedGrounds: {for (var i = 0; i < groundsCount; i++) i: false},
          statutoryDeclarationAccepted: false,
        ));

  void toggleCitation(String citationId, bool value) {
    final updated = Map<String, bool>.from(state.verifiedCitations);
    updated[citationId] = value;
    state = VerificationGateState(
      verifiedCitations: updated,
      verifiedGrounds: state.verifiedGrounds,
      statutoryDeclarationAccepted: state.statutoryDeclarationAccepted,
    );
  }

  void toggleGround(int index, bool value) {
    final updated = Map<int, bool>.from(state.verifiedGrounds);
    updated[index] = value;
    state = VerificationGateState(
      verifiedCitations: state.verifiedCitations,
      verifiedGrounds: updated,
      statutoryDeclarationAccepted: state.statutoryDeclarationAccepted,
    );
  }

  void setStatutoryDeclaration(bool accepted) {
    state = VerificationGateState(
      verifiedCitations: state.verifiedCitations,
      verifiedGrounds: state.verifiedGrounds,
      statutoryDeclarationAccepted: accepted,
    );
  }
}
