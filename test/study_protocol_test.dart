import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/config/study_protocol.dart';

void main() {
  group('Requirements baseline', () {
    test('retains the requested six-session and 540-item structure', () {
      expect(StudyProtocol.sessionCount, 6);
      expect(StudyProtocol.realWordPoolCount, 270);
      expect(StudyProtocol.nonWordPoolCount, 270);
      expect(StudyProtocol.totalItemBankCount, 540);
      expect(StudyProtocol.requirementsArithmeticIsConsistent, isTrue);
    });

    test('retains 90 presentations split into five practice and 85 test', () {
      expect(StudyProtocol.presentationsPerSession, 90);
      expect(StudyProtocol.practicePresentationsPerSession, 5);
      expect(StudyProtocol.testPresentationsPerSession, 85);
    });

    test('retains 10-second stimulus display and reward every 10 answers', () {
      expect(StudyProtocol.stimulusDisplayDuration, const Duration(seconds: 10));
      expect(StudyProtocol.rewardIntervalAnswers, 10);
    });

    test('does not claim schedule or item-bank approval', () {
      expect(StudyProtocol.sessionScheduleApproved, isFalse);
      expect(StudyProtocol.approvedNonWordCount, 0);
      expect(StudyProtocol.participantWorkflowEnabled, isFalse);
    });
  });
}
