import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/config/assessment_release_gate.dart';

void main() {
  test('current build is permanently fail-closed for participant use', () {
    expect(AssessmentReleaseGate.current.isOpen, isFalse);
    expect(AssessmentReleaseGate.current.blockers, hasLength(19));
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
        'Written native Kannada approval for all 270 non-word candidates is missing.',
      ),
    );
    expect(
      AssessmentReleaseGate.current.blockers,
      contains(
        'The permanent Android package ID and institution signing owner are not approved.',
      ),
    );
    expect(
      AssessmentReleaseGate.current.blockers,
      contains('A signed field-release approval manifest is not present.'),
    );
  });
}
