import '../../../../core/time/local_timestamp.dart';

class TrialRecord {
  const TrialRecord({
    required this.trialUuid,
    required this.sessionUuid,
    required this.ordinal,
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

  /// One-based position in the frozen session manifest.
  final int ordinal;

  final String phase;

  /// One-based position within the practice or test phase.
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

  /// Matches the SQLite trials.status CHECK constraint.
  String get status {
    if (response == null) return 'presented';
    if (response == 'none') return 'no_response';
    return 'answered';
  }

  Map<String, Object?> toDatabaseMap() {
    if (ordinal < 1 || trialNumber < 1 || coinsSoFar < 0) {
      throw ArgumentError(
        'Trial ordinal, phase trial number and coin count must be valid.',
      );
    }
    if (phase != 'practice' && phase != 'test') {
      throw ArgumentError.value(phase, 'phase', 'Invalid trial phase.');
    }
    if (itemType != 'word' && itemType != 'nonword') {
      throw ArgumentError.value(itemType, 'itemType', 'Invalid item type.');
    }
    if (itemId.trim().isEmpty || itemText.trim().isEmpty) {
      throw ArgumentError('Trial item ID and text are required.');
    }
    if (itemType == 'nonword' &&
        (nonWordMethod == null || nonWordMethod!.trim().isEmpty)) {
      throw ArgumentError('A non-word trial must retain its construction method.');
    }
    if (itemType == 'word' && nonWordMethod != null) {
      throw ArgumentError('A real-word trial cannot have a non-word method.');
    }
    if (response != null &&
        response != 'word' &&
        response != 'nonword' &&
        response != 'none') {
      throw ArgumentError.value(response, 'response', 'Invalid response.');
    }
    if (correct != null && (response == null || response == 'none')) {
      throw ArgumentError(
        'Correctness must be blank when there is no scored response.',
      );
    }
    if (reactionTimeMs != null && reactionTimeMs! < 0) {
      throw ArgumentError.value(reactionTimeMs, 'reactionTimeMs');
    }

    if (response == null || response == 'none') {
      if (reactionTimeMs != null || answeredAt != null) {
        throw ArgumentError(
          'Presented and no-response trials must not contain response timing.',
        );
      }
    } else {
      if (reactionTimeMs == null || answeredAt == null) {
        throw ArgumentError(
          'Answered trials require reaction time and answer timestamp.',
        );
      }
      if (answeredAt!.isBefore(shownAt)) {
        throw ArgumentError('Answer timestamp cannot precede stimulus display.');
      }
    }

    return <String, Object?>{
      'trial_uuid': trialUuid,
      'session_uuid': sessionUuid,
      'ordinal': ordinal,
      'phase': phase,
      'trial_no': trialNumber,
      'item_id': itemId,
      'item_text': itemText,
      'item_type': itemType,
      'nonword_method': nonWordMethod,
      'response': response,
      'correct': correct == null ? null : (correct! ? 1 : 0),
      'rt_ms': reactionTimeMs,
      'shown_at': LocalTimestamp.format(shownAt),
      'answered_at':
          answeredAt == null ? null : LocalTimestamp.format(answeredAt!),
      'status': status,
      'coins_so_far': coinsSoFar,
      'app_version': appVersion,
      'items_file_version': itemBankVersion,
    };
  }
}
