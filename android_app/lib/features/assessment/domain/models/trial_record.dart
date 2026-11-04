class TrialRecord {
  const TrialRecord({
    required this.trialUuid,
    required this.sessionUuid,
    required this.phase,
    required this.trialNumber,
    required this.itemId,
    required this.itemText,
    required this.itemType,
    required this.shownAt,
    required this.coinsSoFar,
    required this.appVersion,
    required this.itemBankVersion,
    this.nonWordMethod,
    this.response,
    this.correct,
    this.reactionTimeMs,
    this.answeredAt,
  });

  final String trialUuid;
  final String sessionUuid;
  final String phase;
  final int trialNumber;
  final String itemId;
  final String itemText;
  final String itemType;
  final String? nonWordMethod;
  final String? response;
  final bool? correct;
  final int? reactionTimeMs;
  final DateTime shownAt;
  final DateTime? answeredAt;
  final int coinsSoFar;
  final String appVersion;
  final String itemBankVersion;

  Map<String, Object?> toDatabaseMap() {
    if (phase != 'practice' && phase != 'test') {
      throw ArgumentError.value(phase, 'phase', 'Invalid trial phase.');
    }
    if (response != null &&
        response != 'word' &&
        response != 'nonword' &&
        response != 'none') {
      throw ArgumentError.value(response, 'response', 'Invalid response.');
    }
    if (trialNumber < 1 || coinsSoFar < 0) {
      throw ArgumentError('Trial number and coin count must be non-negative.');
    }
    if (correct != null && response == null) {
      throw ArgumentError(
        'Correctness cannot be recorded when no response exists.',
      );
    }
    if (reactionTimeMs != null && reactionTimeMs! < 0) {
      throw ArgumentError.value(reactionTimeMs, 'reactionTimeMs');
    }

    return <String, Object?>{
      'trial_uuid': trialUuid,
      'session_uuid': sessionUuid,
      'phase': phase,
      'trial_no': trialNumber,
      'item_id': itemId,
      'item_text': itemText,
      'item_type': itemType,
      'nonword_method': nonWordMethod,
      'response': response,
      'correct': correct == null ? null : (correct! ? 1 : 0),
      'rt_ms': reactionTimeMs,
      'shown_at': shownAt.toIso8601String(),
      'answered_at': answeredAt?.toIso8601String(),
      'coins_so_far': coinsSoFar,
      'app_version': appVersion,
      'items_file_version': itemBankVersion,
    };
  }
}
