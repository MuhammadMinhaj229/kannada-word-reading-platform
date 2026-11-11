import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/allocation_proposal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('loads the six-session 45 real + 32 non-word proposal', () async {
    final proposal = await AllocationProposal.load();

    expect(proposal.sessionCount, 6);
    expect(proposal.realWordsPerSession, 45);
    expect(proposal.nonWordsPerSession, 32);
    expect(proposal.scoredItemsPerSession, 77);
    expect(proposal.allocatedRealWordCount, 270);
    expect(proposal.allocatedNonWordCount, 192);
    expect(proposal.totalScoredItems, 462);
    expect(proposal.suppliedNonWordCandidateCount, 193);
    expect(proposal.reserveNonWordId, 'N270');
    expect(proposal.participantWorkflowEnabled, isFalse);
    expect(proposal.sessionDistribution, hasLength(6));
    expect(
      proposal.sessionDistribution.every((session) =>
          session.realWords == 45 &&
          session.nonWords == 32 &&
          session.scoredItems == 77),
      isTrue,
    );
  });

  test('rejects a changed session count or item ratio', () async {
    final proposal = await AllocationProposal.load();
    final invalid = AllocationProposal(
      version: proposal.version,
      status: proposal.status,
      sessionCount: 6,
      realWordsPerSession: 45,
      nonWordsPerSession: 33,
      scoredItemsPerSession: 78,
      allocatedRealWordCount: 270,
      allocatedNonWordCount: 198,
      suppliedNonWordCandidateCount: 193,
      reserveNonWordId: proposal.reserveNonWordId,
      participantWorkflowEnabled: false,
      practicePolicy: proposal.practicePolicy,
      sessionDistribution: proposal.sessionDistribution,
    );

    expect(invalid.validate, throwsFormatException);
  });
}
