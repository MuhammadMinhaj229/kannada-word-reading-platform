/// Fail-closed field-release approval gate.
///
/// These approvals are intentionally absent from the repository. They must be
/// supplied by the institution/study team through a signed, versioned release
/// manifest after the protocol, item bank, language assets, data governance
/// and target-device acceptance are complete.
class FieldReleaseApproval {
  const FieldReleaseApproval({
    this.protocolReference,
    this.allocationReference,
    this.itemBankReference,
    this.itemBankSha256,
    this.kannadaReviewReference,
    this.audioApprovalReference,
    this.fontApprovalReference,
    this.ethicsAndConsentReference,
    this.dataGovernanceReference,
    this.timeoutAndNoResponseReference,
    this.rewardRuleReference,
    this.targetDeviceAcceptanceReference,
    this.exportSchemaReference,
    this.supervisorPinProvisioned = false,
    this.signedRelease = false,
  });

  final String? protocolReference;
  final String? allocationReference;
  final String? itemBankReference;
  final String? itemBankSha256;
  final String? kannadaReviewReference;
  final String? audioApprovalReference;
  final String? fontApprovalReference;
  final String? ethicsAndConsentReference;
  final String? dataGovernanceReference;
  final String? timeoutAndNoResponseReference;
  final String? rewardRuleReference;
  final String? targetDeviceAcceptanceReference;
  final String? exportSchemaReference;
  final bool supervisorPinProvisioned;
  final bool signedRelease;
}

class AssessmentReleaseGate {
  const AssessmentReleaseGate(this.approval);

  /// No signed release manifest is present in the current source tree.
  static const current = AssessmentReleaseGate(FieldReleaseApproval());

  final FieldReleaseApproval approval;

  bool get isOpen => blockers.isEmpty;

  List<String> get blockers {
    final result = <String>[];

    void requireReference(String? value, String message) {
      if (value == null || value.trim().isEmpty) result.add(message);
    }

    requireReference(
      approval.protocolReference,
      'Written PI/statistician approval of the final study protocol is missing.',
    );
    requireReference(
      approval.allocationReference,
      'The six-session item allocation and ordering method are not approved.',
    );
    requireReference(
      approval.itemBankReference,
      'The final 270 real-word and 270 non-word item bank is not approved.',
    );

    final hash = approval.itemBankSha256;
    if (hash == null || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) {
      result.add('A verified SHA-256 hash for the approved item bank is missing.');
    }

    requireReference(
      approval.kannadaReviewReference,
      'Native Kannada linguistic review and written sign-off are missing.',
    );
    requireReference(
      approval.audioApprovalReference,
      'The bundled Kannada instruction recordings are not approved.',
    );
    requireReference(
      approval.fontApprovalReference,
      'The bundled Kannada font and glyph-shaping review are not approved.',
    );
    requireReference(
      approval.ethicsAndConsentReference,
      'Institutional ethics and participant/parent consent approval is missing.',
    );
    requireReference(
      approval.dataGovernanceReference,
      'Institutional data governance, retention and device-loss procedures are missing.',
    );
    requireReference(
      approval.timeoutAndNoResponseReference,
      'The response timeout and no-response handling rule is not approved.',
    );
    requireReference(
      approval.rewardRuleReference,
      'The reward cadence and practice/scored-trial treatment are not approved.',
    );
    requireReference(
      approval.targetDeviceAcceptanceReference,
      'Acceptance on the actual study tablet is not recorded.',
    );
    requireReference(
      approval.exportSchemaReference,
      'The study export dictionary and REDCap mapping are not signed off.',
    );

    if (!approval.supervisorPinProvisioned) {
      result.add('A supervisor PIN has not been provisioned securely.');
    }
    if (!approval.signedRelease) {
      result.add('A signed field-release approval manifest is not present.');
    }

    return List<String>.unmodifiable(result);
  }
}
