/// Validates response/timing invariants before a trial is committed.
class TrialResponseValidation {
  const TrialResponseValidation._();

  static void validate({
    required String response,
    required int? reactionTimeMs,
    required DateTime shownAt,
    required DateTime? answeredAt,
  }) {
    if (response != 'word' && response != 'nonword' && response != 'none') {
      throw ArgumentError.value(response, 'response');
    }

    if (response == 'none') {
      if (reactionTimeMs != null || answeredAt != null) {
        throw ArgumentError(
          'A no-response trial must keep reaction time and answer time blank.',
        );
      }
      return;
    }

    if (reactionTimeMs == null || answeredAt == null) {
      throw ArgumentError(
        'Answered trials require reaction time and answer timestamp.',
      );
    }
    if (reactionTimeMs < 0) {
      throw ArgumentError.value(reactionTimeMs, 'reactionTimeMs');
    }
    if (answeredAt.isBefore(shownAt)) {
      throw ArgumentError(
        'The answer timestamp cannot precede the committed presentation time.',
      );
    }
  }
}
