import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/services/session_recovery_policy.dart';

void main() {
  group('SessionRecoveryPolicy', () {
    test('allows the automatic path only for an interrupted session without a pending trial', () {
      expect(
        SessionRecoveryPolicy.evaluate(
          sessionStatus: 'interrupted',
          hasUnansweredPresentedTrial: false,
        ),
        SessionRecoveryDisposition.readyToResume,
      );
    });

    test('requires supervisor review when a presented stimulus has no committed response', () {
      expect(
        SessionRecoveryPolicy.evaluate(
          sessionStatus: 'interrupted',
          hasUnansweredPresentedTrial: true,
        ),
        SessionRecoveryDisposition.requiresSupervisorReview,
      );
    });

    test('rejects a session that is not interrupted', () {
      for (final status in <String>['in_progress', 'completed', 'abandoned']) {
        expect(
          SessionRecoveryPolicy.evaluate(
            sessionStatus: status,
            hasUnansweredPresentedTrial: false,
          ),
          SessionRecoveryDisposition.notInterrupted,
        );
      }
    });
  });
}
