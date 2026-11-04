/// Working study-protocol values, pending written study-team approval.
abstract final class StudyProtocol {
  static const int sessionCount = 6;
  static const int realWordPoolCount = 270;
  static const int plannedNonWordPoolCount = 194;
  static const int uploadedNonWordCsvCount = 193;

  static const int realWordsPerSession = 45;
  static const int nonWordsPerSession = 32;
  static const int scoredItemsPerSession =
      realWordsPerSession + nonWordsPerSession;
  static const int practiceItemsPerSession = 5;

  static const int allocatedNonWords =
      sessionCount * nonWordsPerSession;
  static const int reserveNonWords =
      plannedNonWordPoolCount - allocatedNonWords;

  static const bool practiceIsAdditionalToScoredItems = true;
  static const bool itemBankApproved = false;

  static const int intendedTotalPool =
      realWordPoolCount + plannedNonWordPoolCount;
  static const int uploadedTotalPool =
      realWordPoolCount + uploadedNonWordCsvCount;

  static const bool allocationArithmeticIsValid =
      sessionCount * realWordsPerSession == realWordPoolCount &&
      sessionCount * nonWordsPerSession + reserveNonWords ==
          plannedNonWordPoolCount &&
      scoredItemsPerSession == 77 &&
      reserveNonWords == 2;
}
