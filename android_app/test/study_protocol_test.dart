import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/config/study_protocol.dart';

void main() {
  group('StudyProtocol', () {
    test('uses the six-session 45 + 32 allocation', () {
      expect(StudyProtocol.sessionCount, 6);
      expect(StudyProtocol.realWordsPerSession, 45);
      expect(StudyProtocol.nonWordsPerSession, 32);
      expect(StudyProtocol.scoredItemsPerSession, 77);
    });

    test('allocates 462 items and retains two non-word reserves', () {
      expect(
        StudyProtocol.sessionCount * StudyProtocol.scoredItemsPerSession,
        462,
      );
      expect(StudyProtocol.allocatedNonWords, 192);
      expect(StudyProtocol.reserveNonWords, 2);
      expect(StudyProtocol.allocationArithmeticIsValid, isTrue);
    });

    test('records the current CSV count discrepancy explicitly', () {
      expect(StudyProtocol.plannedNonWordPoolCount, 194);
      expect(StudyProtocol.uploadedNonWordCsvCount, 193);
      expect(StudyProtocol.uploadedTotalPool, 463);
      expect(StudyProtocol.intendedTotalPool, 464);
    });

    test('does not mark the item bank as approved', () {
      expect(StudyProtocol.itemBankApproved, isFalse);
    });
  });
}
