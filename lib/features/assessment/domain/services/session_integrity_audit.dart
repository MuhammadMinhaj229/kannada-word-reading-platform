/// Read-only audit of a persisted session against its frozen allocation.
class SessionIntegrityReport {
  SessionIntegrityReport(Iterable<String> errors)
      : errors = List<String>.unmodifiable(errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;

  int get issueCount => errors.length;
}

class SessionIntegrityAudit {
  const SessionIntegrityAudit._();

  static SessionIntegrityReport inspect({
    required Map<String, Object?> session,
    required List<Map<String, Object?>> manifestItems,
    required List<Map<String, Object?>> trials,
  }) {
    final errors = <String>[];
    void add(String message) {
      if (!errors.contains(message)) errors.add(message);
    }

    final sessionUuid = session['session_uuid'];
    if (sessionUuid is! String || sessionUuid.isEmpty) {
      add('Session UUID is missing.');
    }

    final sessionStatus = session['status'];
    const validSessionStatuses = <String>{
      'in_progress',
      'interrupted',
      'completed',
      'abandoned',
    };
    if (sessionStatus is! String ||
        !validSessionStatuses.contains(sessionStatus)) {
      add('Session status is invalid.');
    }

    final nextOrdinal = session['next_ordinal'];
    if (nextOrdinal is! int || nextOrdinal < 1) {
      add('Session next-ordinal cursor is invalid.');
    }

    final orderedManifest = List<Map<String, Object?>>.of(manifestItems)
      ..sort((a, b) => _integer(a['ordinal']).compareTo(_integer(b['ordinal'])));
    if (orderedManifest.isEmpty) {
      add('The frozen session manifest is empty.');
    }

    final manifestByOrdinal = <int, Map<String, Object?>>{};
    final manifestIds = <String>{};
    final practiceNumbers = <int>{};
    final testNumbers = <int>{};
    var expectedPracticeNumber = 0;
    var expectedTestNumber = 0;

    for (var index = 0; index < orderedManifest.length; index += 1) {
      final item = orderedManifest[index];
      final ordinal = item['ordinal'];
      if (ordinal is! int || ordinal != index + 1) {
        add('Manifest ordinals are not sequential from 1.');
      } else if (manifestByOrdinal.containsKey(ordinal)) {
        add('Manifest ordinal $ordinal is duplicated.');
      } else {
        manifestByOrdinal[ordinal] = item;
      }

      final itemId = item['item_id'];
      if (itemId is! String || itemId.trim().isEmpty) {
        add('Manifest item at position ${index + 1} has no item ID.');
      } else if (!manifestIds.add(itemId)) {
        add('Manifest item ID $itemId is duplicated.');
      }

      final phase = item['phase'];
      final phaseTrialNumber = item['phase_trial_no'];
      if (phase == 'practice') {
        expectedPracticeNumber += 1;
        if (phaseTrialNumber != expectedPracticeNumber) {
          add('Practice trial numbering is not sequential.');
        }
        if (phaseTrialNumber is int) practiceNumbers.add(phaseTrialNumber);
      } else if (phase == 'test') {
        expectedTestNumber += 1;
        if (phaseTrialNumber != expectedTestNumber) {
          add('Test trial numbering is not sequential.');
        }
        if (phaseTrialNumber is int) testNumbers.add(phaseTrialNumber);
      } else {
        add('Manifest item at position ${index + 1} has an invalid phase.');
      }

      final itemType = item['item_type'];
      if (itemType != 'word' && itemType != 'nonword') {
        add('Manifest item at position ${index + 1} has an invalid item type.');
      }
      if (itemId is String && itemId.isEmpty) {
        add('Manifest item at position ${index + 1} has an empty item ID.');
      }
    }

    final trialByOrdinal = <int, Map<String, Object?>>{};
    final trialIds = <String>{};
    for (final trial in trials) {
      final ordinal = trial['ordinal'];
      if (ordinal is! int || ordinal < 1) {
        add('A trial has an invalid ordinal.');
        continue;
      }
      if (trialByOrdinal.containsKey(ordinal)) {
        add('Trial ordinal $ordinal is duplicated.');
        continue;
      }
      trialByOrdinal[ordinal] = trial;

      final trialUuid = trial['trial_uuid'];
      if (trialUuid is! String || trialUuid.trim().isEmpty) {
        add('Trial at ordinal $ordinal has no UUID.');
      } else if (!trialIds.add(trialUuid)) {
        add('Trial UUID $trialUuid is duplicated.');
      }

      if (trial['session_uuid'] != sessionUuid) {
        add('Trial at ordinal $ordinal references a different session.');
      }

      final frozen = manifestByOrdinal[ordinal];
      if (frozen == null) {
        add('Trial at ordinal $ordinal is absent from the frozen manifest.');
        continue;
      }

      for (final field in <String>[
        'phase',
        'item_id',
        'item_text',
        'item_type',
        'nonword_method',
      ]) {
        final trialField = field == 'phase' ? 'phase' : field;
        if (trial[trialField] != frozen[field]) {
          add('Trial at ordinal $ordinal does not match manifest field $field.');
        }
      }
      if (trial['trial_no'] != frozen['phase_trial_no']) {
        add('Trial at ordinal $ordinal does not match its phase trial number.');
      }

      _auditTrialState(trial, ordinal, add);
    }

    if (nextOrdinal is int && nextOrdinal > 0) {
      final manifestCount = orderedManifest.length;
      if (nextOrdinal > manifestCount + 1) {
        add('Session cursor is beyond the frozen manifest.');
      }

      for (var ordinal = 1; ordinal < nextOrdinal; ordinal += 1) {
        final trial = trialByOrdinal[ordinal];
        if (trial == null) {
          add('Completed cursor position $ordinal has no persisted trial.');
        } else if (trial['status'] != 'answered' &&
            trial['status'] != 'no_response') {
          add('Cursor position $ordinal is not in a terminal trial state.');
        }
      }

      final currentTrial = trialByOrdinal[nextOrdinal];
      if (currentTrial != null && currentTrial['status'] != 'presented') {
        add('The current cursor position is already terminal.');
      }

      for (final ordinal in trialByOrdinal.keys) {
        if (ordinal > nextOrdinal) {
          add('Trial ordinal $ordinal is ahead of the session cursor.');
        }
      }

      if (trialByOrdinal.length > nextOrdinal) {
        add('Persisted trial count exceeds the session cursor boundary.');
      }
    }

    final completedAt = session['completed_at'];
    if (sessionStatus == 'completed') {
      if (nextOrdinal is int &&
          nextOrdinal != orderedManifest.length + 1) {
        add('Completed session cursor does not follow the final manifest item.');
      }
      if (completedAt is! String ||
          DateTime.tryParse(completedAt) == null) {
        add('Completed session has no valid completion timestamp.');
      }
      if (trialByOrdinal.values.any((trial) => trial['status'] == 'presented')) {
        add('Completed session contains an unanswered presented trial.');
      }
    } else if (completedAt != null) {
      add('A non-completed session has a completion timestamp.');
    }

    return SessionIntegrityReport(errors);
  }

  static void _auditTrialState(
    Map<String, Object?> trial,
    int ordinal,
    void Function(String) add,
  ) {
    final status = trial['status'];
    final response = trial['response'];
    final correct = trial['correct'];
    final reactionTime = trial['rt_ms'];
    final answeredAtRaw = trial['answered_at'];
    final shownAtRaw = trial['shown_at'];

    final shownAt = shownAtRaw is String
        ? DateTime.tryParse(shownAtRaw)
        : null;
    if (shownAt == null) {
      add('Trial at ordinal $ordinal has an invalid presentation timestamp.');
    }

    switch (status) {
      case 'presented':
        if (response != null ||
            correct != null ||
            reactionTime != null ||
            answeredAtRaw != null) {
          add('Presented trial at ordinal $ordinal contains response data.');
        }
      case 'answered':
        if (response != 'word' && response != 'nonword') {
          add('Answered trial at ordinal $ordinal has an invalid response.');
        }
        if (correct != 0 && correct != 1) {
          add('Answered trial at ordinal $ordinal has an invalid correctness value.');
        }
        if (reactionTime is! int || reactionTime < 0) {
          add('Answered trial at ordinal $ordinal has invalid reaction time.');
        }
        final answeredAt = answeredAtRaw is String
            ? DateTime.tryParse(answeredAtRaw)
            : null;
        if (answeredAt == null ||
            shownAt == null ||
            answeredAt.isBefore(shownAt)) {
          add('Answered trial at ordinal $ordinal has an invalid answer timestamp.');
        }
        final itemType = trial['item_type'];
        if ((response == itemType) != (correct == 1)) {
          add('Answered trial at ordinal $ordinal has inconsistent correctness.');
        }
      case 'no_response':
        if (response != 'none' ||
            correct != null ||
            reactionTime != null ||
            answeredAtRaw != null) {
          add('No-response trial at ordinal $ordinal contains inconsistent response data.');
        }
      default:
        add('Trial at ordinal $ordinal has an invalid status.');
    }
  }

  static int _integer(Object? value) => value is int ? value : -1;
}
