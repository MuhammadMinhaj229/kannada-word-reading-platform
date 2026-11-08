/// Interface used by the persistence boundary so every participant-data
/// mutation can be tested with an explicit test authorizer.
abstract interface class AssessmentReleaseAuthorization {
  bool get isOpen;
  List<String> get blockers;
}

/// Fail-closed field-release gate.
///
/// This branch intentionally exposes no constructor that can open the gate.
/// A future release must add a reviewed signature verifier tied to a study-team
/// public key and a signed, versioned release manifest. Setting booleans or
/// supplying reference strings in application code must never unlock a study.
class AssessmentReleaseGate implements AssessmentReleaseAuthorization {
  const AssessmentReleaseGate._();

  static const current = AssessmentReleaseGate._();

  static const List<String> _blockers = <String>[
    'Written PI/statistician approval of the final study protocol is missing.',
    'The six-session item allocation and ordering method are not approved.',
    'Written native Kannada approval for all 270 non-word candidates is missing.',
    'A verified SHA-256 hash for the approved item bank is missing.',
    'Native Kannada linguistic review and written sign-off are missing.',
    'The bundled Kannada instruction recordings are not approved.',
    'The bundled Kannada font and glyph-shaping review are not approved.',
    'Institutional ethics and participant/parent consent approval is missing.',
    'Institutional data governance, retention and device-loss procedures are missing.',
    'The response timeout and no-response handling rule is not approved.',
    'The reward cadence and practice/scored-trial treatment are not approved.',
    'Session interruption, resume and restart behavior is not approved.',
    'Completed-session repeat authorization and restart behavior are not approved.',
    'The same-child same-day session rule is not approved.',
    'Acceptance on the actual study tablet is not recorded.',
    'The study export dictionary and REDCap mapping are not signed off.',
    'A supervisor PIN has not been provisioned securely.',
    'The permanent Android package ID and institution signing owner are not approved.',
    'A signed field-release approval manifest is not present.',
  ];

  @override
  bool get isOpen => false;

  @override
  List<String> get blockers => _blockers;
}
