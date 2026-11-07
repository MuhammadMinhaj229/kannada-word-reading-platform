/// Requirements baseline transcribed from the 2 Nov 2026 application
/// requirements document. These values describe the requested design; they
/// are not, by themselves, evidence that the study protocol was approved.
///
/// Never change counts, randomisation, timeout, rewards or session scheduling
/// from an engineering assumption. A signed study-team approval is required
/// before a field release can be enabled.
abstract final class StudyProtocol {
  static const String requirementsVersion = 'KWR-REQ-2026-11-02';

  static const int sessionCount = 6;
  static const int realWordPoolCount = 270;
  static const int nonWordPoolCount = 270;
  static const int totalItemBankCount = realWordPoolCount + nonWordPoolCount;

  static const int presentationsPerSession = 90;
  static const int practicePresentationsPerSession = 5;
  static const int testPresentationsPerSession = 85;

  static const Duration stimulusDisplayDuration = Duration(seconds: 10);
  static const int rewardIntervalAnswers = 10;

  /// The source requirements state one session per day on different days,
  /// followed by "(will be finalized after discussion with Debarati)".
  static const bool sessionScheduleApproved = false;

  /// Suganya's written approval for all 270 reviewed non-words is required.
  static const int structurallyAuditedNonWordCandidates = 270;
  static const int approvedNonWordCount = 0;

  /// No participant data collection is enabled in this repository revision.
  static const bool participantWorkflowEnabled = false;

  static const bool requirementsArithmeticIsConsistent =
      totalItemBankCount == 540 &&
      sessionCount * presentationsPerSession == 540 &&
      practicePresentationsPerSession + testPresentationsPerSession ==
          presentationsPerSession;
}
