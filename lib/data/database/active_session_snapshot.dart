import '../../features/assessment/domain/models/session_allocation.dart';

class ActiveSessionSnapshot {
  const ActiveSessionSnapshot({
    required this.sessionUuid,
    required this.childId,
    required this.assessorId,
    required this.sessionNumber,
    required this.status,
    required this.nextOrdinal,
    required this.coinsSoFar,
    required this.nextTrial,
    required this.presentedTrialUuid,
    required this.presentedAt,
  });

  final String sessionUuid;
  final String childId;
  final String assessorId;
  final int sessionNumber;
  final String status;
  final int nextOrdinal;
  final int coinsSoFar;
  final PlannedTrial? nextTrial;

  /// A non-null value means a trial was committed as visible but no answer
  /// was committed. Resume/restart behavior for this case is a study-team
  /// decision; the application must not silently create another attempt.
  final String? presentedTrialUuid;
  final String? presentedAt;

  bool get hasUnansweredPresentedTrial => presentedTrialUuid != null;
}
