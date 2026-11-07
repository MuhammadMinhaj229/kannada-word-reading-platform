import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/session_allocation.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item.dart';
import 'package:padalab_android/features/assessment/domain/services/session_allocator.dart';

void main() {
  const allocator = SessionAllocator();
  const checksum = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  SessionAllocation manifest({
    int sessionNumber = 1,
    String protocolApprovalReference = 'PI-APPROVAL-2026-001',
    String allocationApprovalReference = 'STAT-APPROVAL-2026-001',
    String itemBankSha256 = checksum,
    int practiceCount = 5,
    int testCount = 85,
  }) {
    final trials = <PlannedTrial>[];
    var ordinal = 1;

    for (var index = 1; index <= practiceCount; index += 1) {
      trials.add(
        PlannedTrial(
          ordinal: ordinal++,
          phase: TrialPhase.practice,
          phaseTrialNumber: index,
          item: StudyItem(
            id: 'P${index.toString().padLeft(3, '0')}',
            text: 'Practice$index',
            type: StudyItemType.realWord,
          ),
        ),
      );
    }

    for (var index = 1; index <= testCount; index += 1) {
      trials.add(
        PlannedTrial(
          ordinal: ordinal++,
          phase: TrialPhase.test,
          phaseTrialNumber: index,
          item: StudyItem(
            id: 'T${index.toString().padLeft(3, '0')}',
            text: 'Test$index',
            type: index.isEven
                ? StudyItemType.realWord
                : StudyItemType.nonWord,
            nonWordMethod: index.isEven ? null : 'fixture_method',
          ),
        ),
      );
    }

    return SessionAllocation(
      sessionNumber: sessionNumber,
      protocolVersion: 'KWR-REQ-2026-11-02',
      itemBankVersion: 'bank-v1',
      itemBankSha256: itemBankSha256,
      protocolApprovalReference: protocolApprovalReference,
      allocationApprovalReference: allocationApprovalReference,
      orderedTrials: trials,
    );
  }

  test('accepts and preserves a complete approved frozen manifest', () {
    final supplied = manifest();
    final restored = allocator.validateAndRestore(supplied);

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
    expect(
      () => allocator.validateAndRestore(
        manifest(protocolApprovalReference: ''),
      ),
      throwsArgumentError,
    );
    expect(
      () => allocator.validateAndRestore(
        manifest(allocationApprovalReference: ''),
      ),
      throwsArgumentError,
    );
  });

  test('rejects the unapproved 45 plus 32 allocation proposal', () {
    expect(
      () => allocator.validateAndRestore(
        manifest(practiceCount: 5, testCount: 77),
      ),
      throwsArgumentError,
    );
  });

  test('rejects an invalid bank checksum', () {
    expect(
      () => allocator.validateAndRestore(
        manifest(itemBankSha256: 'not-a-hash'),
      ),
      throwsArgumentError,
    );
  });

  test('rejects session numbers outside the requested six', () {
    expect(
      () => allocator.validateAndRestore(manifest(sessionNumber: 7)),
      throwsArgumentError,
    );
  });
}
