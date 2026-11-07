import '../models/session_allocation.dart';

/// Validates a frozen allocation created and approved outside the runtime.
///
/// Random allocation was deliberately removed because the only in-repository
/// allocation proposal (45 real + 32 non-words per session) conflicts with the
/// formal requirements document and was marked "not approved".
class SessionAllocator {
  const SessionAllocator();

  List<PlannedTrial> validateAndRestore(SessionAllocation manifest) {
    manifest.validate();
    return manifest.orderedTrials;
  }
}
