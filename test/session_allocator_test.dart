import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/session_allocation.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item_bank.dart';
import 'package:padalab_android/features/assessment/domain/services/session_allocator.dart';

import 'helpers/test_item_bank.dart';

void main() {
  const allocator = SessionAllocator();

  SessionAllocation manifest({
    required StudyItemBank itemBank,
    int sessionNumber = 1,
    String protocolApprovalReference = 'PI-APPROVAL-2026-001',
    String allocationApprovalReference = 'STAT-APPROVAL-2026-001',
    String? itemBankSha256,
    int practiceCount = 5,
    int testCount = 85,
  }) {
    final realWords = itemBank.items
        .where((item) => item.type == StudyItemType.realWord)
        .toList(growable: false);
    final nonWords = itemBank.items
        .where((item) => item.type == StudyItemType.nonWord)
        .toList(growable: false);
    final trials = <PlannedTrial>[];
    var ordinal = 1;

    for (var index = 0; index < practiceCount; index += 1) {
      trials.add(
        PlannedTrial(
          ordinal: ordinal++,
          phase: TrialPhase.practice,
          phaseTrialNumber: index + 1,
          item: realWords[index],
        ),
      );
    }

    for (var index = 0; index < testCount; index += 1) {
      final useRealWord = index.isEven;
      final item = useRealWord
          ? realWords[practiceCount + (index ~/ 2)]
          : nonWords[index ~/ 2];
      trials.add(
        PlannedTrial(
          ordinal: ordinal++,
          phase: TrialPhase.test,
          phaseTrialNumber: index + 1,
          item: item,
        ),
      );
    }

    return SessionAllocation(
      sessionNumber: sessionNumber,
      protocolVersion: 'KWR-REQ-2026-11-02',
      itemBankVersion: itemBank.version,
      itemBankSha256: itemBankSha256 ?? itemBank.sha256,
      protocolApprovalReference: protocolApprovalReference,
      allocationApprovalReference: allocationApprovalReference,
      orderedTrials: trials,
    );
  }

  test('accepts and preserves a complete approved frozen manifest', () {
    final bank = createValidTestItemBank();
    final supplied = manifest(itemBank: bank);
    final restored = allocator.validateAndRestore(
      manifest: supplied,
      itemBank: bank,
    );

    expect(restored, hasLength(90));
    expect(restored.first.phase, TrialPhase.practice);
    expect(restored[4].phaseTrialNumber, 5);
    expect(restored[5].phase, TrialPhase.test);
    expect(restored.last.phaseTrialNumber, 85);
    expect(
      restored.map((trial) => trial.item.id).toList(),
      supplied.orderedTrials.map((trial) => trial.item.id).toList(),
    );
  });

  test('rejects an allocation without written approval references', () {
    final bank = createValidTestItemBank();
    expect(
      () => allocator.validateAndRestore(
        manifest: manifest(itemBank: bank, protocolApprovalReference: ''),
        itemBank: bank,
      ),
      throwsArgumentError,
    );
    expect(
      () => allocator.validateAndRestore(
        manifest: manifest(itemBank: bank, allocationApprovalReference: ''),
        itemBank: bank,
      ),
      throwsArgumentError,
    );
  });

  test('rejects the unapproved 45 plus 32 allocation proposal', () {
    final bank = createValidTestItemBank();
    expect(
      () => allocator.validateAndRestore(
        manifest: manifest(itemBank: bank, practiceCount: 5, testCount: 77),
        itemBank: bank,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a bank checksum that does not match actual content', () {
    final bank = createValidTestItemBank();
    expect(
      () => allocator.validateAndRestore(
        manifest: manifest(itemBank: bank, itemBankSha256: 'a' * 64),
        itemBank: bank,
      ),
      throwsStateError,
    );
  });

  test('rejects a session number outside the six requested sessions', () {
    final bank = createValidTestItemBank();
    expect(
      () => allocator.validateAndRestore(
        manifest: manifest(itemBank: bank, sessionNumber: 7),
        itemBank: bank,
      ),
      throwsArgumentError,
    );
  });

  test('rejects any trial stimulus not byte-for-byte equal to bank entry', () {
    final bank = createValidTestItemBank();
    final supplied = manifest(itemBank: bank);
    final alteredTrials = List<PlannedTrial>.of(supplied.orderedTrials);
    final original = alteredTrials.first;
    alteredTrials[0] = PlannedTrial(
      ordinal: original.ordinal,
      phase: original.phase,
      phaseTrialNumber: original.phaseTrialNumber,
      item: StudyItem(
        id: original.item.id,
        text: 'not-the-approved-stimulus',
        type: original.item.type,
      ),
    );
    final altered = SessionAllocation(
      sessionNumber: supplied.sessionNumber,
      protocolVersion: supplied.protocolVersion,
      itemBankVersion: supplied.itemBankVersion,
      itemBankSha256: supplied.itemBankSha256,
      protocolApprovalReference: supplied.protocolApprovalReference,
      allocationApprovalReference: supplied.allocationApprovalReference,
      orderedTrials: alteredTrials,
    );

    expect(
      () => allocator.validateAndRestore(manifest: altered, itemBank: bank),
      throwsStateError,
    );
  });
}
