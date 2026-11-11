/// Defines the only safe automatic recovery path for interrupted sessions.
enum SessionRecoveryDisposition {
  /// The session is interrupted and has no unresolved presented trial.
  readyToResume,

  /// A stimulus was already presented but its response was not committed.
  /// The study team must approve the handling before the session can continue.
  requiresSupervisorReview,

  /// The requested session is not currently interrupted.
  notInterrupted,
}

class SessionRecoveryPolicy {
  const SessionRecoveryPolicy._();

  static SessionRecoveryDisposition evaluate({
    required String sessionStatus,
    required bool hasUnansweredPresentedTrial,
  }) {
    if (sessionStatus != 'interrupted') {
      return SessionRecoveryDisposition.notInterrupted;
    }
    if (hasUnansweredPresentedTrial) {
      return SessionRecoveryDisposition.requiresSupervisorReview;
    }
    return SessionRecoveryDisposition.readyToResume;
  }
}
