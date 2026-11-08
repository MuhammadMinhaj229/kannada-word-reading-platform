import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/data/database/assessment_database.dart';
import 'package:padalab_android/data/security/database_key_provider.dart';
import 'package:padalab_android/features/assessment/domain/models/session_allocation.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item.dart';

import 'helpers/test_item_bank.dart';

class _CountingSecureStore implements SecureKeyValueStore {
  int readCalls = 0;
  int writeCalls = 0;

  @override
  Future<String?> read(String key) async {
    readCalls += 1;
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    writeCalls += 1;
  }
}

void main() {

  test('closed field gate rejects trial writes before database/key access', () async {
    final secureStore = _CountingSecureStore();
    final database = AssessmentDatabase(
      keyProvider: DatabaseKeyProvider(store: secureStore),
    );

    const planned = PlannedTrial(
      ordinal: 1,
      phase: TrialPhase.test,
      phaseTrialNumber: 1,
      item: StudyItem(
        id: 'REAL-001',
        text: 'ಮನೆ',
        type: StudyItemType.realWord,
      ),
    );

    await expectLater(
      database.beginTrial(
        sessionUuid: 'TEST-SESSION',
        plannedTrial: planned,
        shownAt: DateTime(2026, 11, 8, 10),
        appVersion: '0.1.0+1',
        itemBankVersion: 'TEST-BANK',
      ),
      throwsA(isA<StateError>()),
    );

    await expectLater(
      database.completeTrial(
        trialUuid: 'TEST-TRIAL',
        response: 'word',
        reactionTimeMs: 250,
        answeredAt: DateTime(2026, 11, 8, 10, 0, 0, 250),
      ),
      throwsA(isA<StateError>()),
    );

    expect(secureStore.readCalls, 0);
    expect(secureStore.writeCalls, 0);
    await database.close();
  });

  test('closed field gate rejects session before database/key access', () async {
    final bank = createValidTestItemBank();
    final manifest = SessionAllocation(
      sessionNumber: 1,
      protocolVersion: 'KWR-REQ-2026-11-02',
      itemBankVersion: bank.version,
      itemBankSha256: bank.sha256,
      protocolApprovalReference: 'TEST-ONLY',
      allocationApprovalReference: 'TEST-ONLY',
      orderedTrials: <PlannedTrial>[
        for (var index = 0; index < 90; index += 1)
          PlannedTrial(
            ordinal: index + 1,
            phase: index < 5 ? TrialPhase.practice : TrialPhase.test,
            phaseTrialNumber: index < 5 ? index + 1 : index - 4,
            item: bank.items[index],
          ),
      ],
    );

    final secureStore = _CountingSecureStore();
    final database = AssessmentDatabase(
      keyProvider: DatabaseKeyProvider(store: secureStore),
    );

    await expectLater(
      database.createSession(
        childId: 'TEST-CHILD',
        assessorId: 'TEST-ASSESSOR',
        deviceId: 'TEST-DEVICE',
        sessionDate: DateTime(2026, 11, 7),
        appVersion: '0.1.0+1',
        manifest: manifest,
        itemBank: bank,
      ),
      throwsA(isA<StateError>()),
    );

    expect(secureStore.readCalls, 0);
    expect(secureStore.writeCalls, 0);
    await database.close();
  });
}
