/// Working study-protocol values, pending written study-team approval.
abstract final class StudyProtocol {
  static const int sessionCount = 6;
  static const int realWordPoolCount = 270;
  // Working-allocation proposal only; it is not the formal DOCX protocol.
  static const int plannedNonWordPoolCount = 194;

  // Latest uploaded nonwords_v1.xlsm audit (5 Nov 2026).
  // All candidates remain pending native-speaker review and written approval.
  static const int uploadedNonWordWorkbookCount = 270;
  static const int approvedNonWordCount = 0;

  // Formal requirements document specifies a 270 + 270 stimulus pool.
  static const int formalRequirementsNonWordPoolCount = 270;

  static const int realWordsPerSession = 45;
  static const int nonWordsPerSession = 32;
  static const int scoredItemsPerSession =
      realWordsPerSession + nonWordsPerSession;
  static const int practiceItemsPerSession = 5;

  static const int allocatedNonWords = sessionCount * nonWordsPerSession;
  static const int reserveNonWords =
      plannedNonWordPoolCount - allocatedNonWords;

  static const bool practiceIsAdditionalToScoredItems = true;
  static const bool itemBankApproved = false;

  static const int workingProposalTotalPool =
      realWordPoolCount + plannedNonWordPoolCount;
  static const int formalRequirementsTotalPool =
      realWordPoolCount + formalRequirementsNonWordPoolCount;
  static const int uploadedTotalPool =
      realWordPoolCount + uploadedNonWordWorkbookCount;

  static const bool allocationArithmeticIsValid =
      sessionCount * realWordsPerSession == realWordPoolCount &&
          sessionCount * nonWordsPerSession + reserveNonWords ==
              plannedNonWordPoolCount &&
          scoredItemsPerSession == 77 &&
          reserveNonWords == 2;
}
