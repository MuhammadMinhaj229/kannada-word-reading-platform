import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/config/assessment_release_gate.dart';

void main() {
  test('current build is permanently fail-closed for participant use', () {
    expect(AssessmentReleaseGate.current.isOpen, isFalse);
    expect(
      AssessmentReleaseGate.current.blockers,
      contains(
        'Written PI/statistician approval of the final study protocol is missing.',
      ),
    );
    expect(
      AssessmentReleaseGate.current.blockers,
      contains(
        'Native Kannada linguistic review and written sign-off are missing.',
      ),
    );
    expect(
      AssessmentReleaseGate.current.blockers,
      contains(
        'The final 270 real-word and 270 non-word item bank is not approved.',
      ),
    );
    expect(
      AssessmentReleaseGate.current.blockers,
      contains('A signed field-release approval manifest is not present.'),
    );
  });

  test('cannot be unlocked by passing approval-shaped values in application code',
      () {
    expect(
      () => AssessmentReleaseGate.current.isOpen = true,
      throwsNoSuchMethodError,
    );
    expect(AssessmentReleaseGate.current.isOpen, isFalse);
  });
}
