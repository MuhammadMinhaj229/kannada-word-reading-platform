import '../models/session_allocation.dart';
import '../models/study_item_bank.dart';

/// Validates and restores a frozen, study-team-approved session allocation.
///
/// Random allocation was deliberately removed because the only in-repository
/// allocation proposal (45 real + 32 non-words per session) conflicts with the
/// formal requirements document and was marked "not approved".
class SessionAllocator {
  const SessionAllocator();

  List<PlannedTrial> validateAndRestore({
    required SessionAllocation manifest,
    required StudyItemBank itemBank,
  }) {
    manifest.validateAgainst(itemBank);
    return manifest.orderedTrials;
  }
}
