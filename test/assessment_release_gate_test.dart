import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/config/assessment_release_gate.dart';

void main() {
  test('default release gate is closed and lists every approval blocker', () {
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
      contains('A signed field-release approval manifest is not present.'),
    );
  });

  test('gate opens only with complete approvals and a 64-character SHA-256',
      () {
    const approval = FieldReleaseApproval(
      protocolReference: 'PI-PROTOCOL-APPROVAL-001',
      allocationReference: 'STAT-ALLOCATION-APPROVAL-001',
      itemBankReference: 'SUGANYA-ITEM-BANK-APPROVAL-001',
      itemBankSha256:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      kannadaReviewReference: 'KANNADA-REVIEW-001',
      audioApprovalReference: 'AUDIO-APPROVAL-001',
      fontApprovalReference: 'FONT-APPROVAL-001',
      ethicsAndConsentReference: 'ETHICS-APPROVAL-001',
      dataGovernanceReference: 'DATA-GOVERNANCE-001',
      timeoutAndNoResponseReference: 'TIMEOUT-POLICY-001',
      rewardRuleReference: 'REWARD-POLICY-001',
      sessionInterruptionPolicyReference: 'RECOVERY-POLICY-001',
      repeatAndRestartPolicyReference: 'REPEAT-POLICY-001',
      sameDaySessionPolicyReference: 'SAME-DAY-POLICY-001',
      targetDeviceAcceptanceReference: 'TABLET-ACCEPTANCE-001',
      exportSchemaReference: 'EXPORT-SCHEMA-001',
      supervisorPinProvisioned: true,
      signedRelease: true,
    );

    const gate = AssessmentReleaseGate(approval);
    expect(gate.isOpen, isTrue);
    expect(gate.blockers, isEmpty);
  });

  test('rejects an invalid item-bank checksum', () {
    const approval = FieldReleaseApproval(itemBankSha256: '1234');
    final gate = AssessmentReleaseGate(approval);

    expect(
      gate.blockers,
      contains(
        'A verified SHA-256 hash for the approved item bank is missing.',
      ),
    );
  });
}
