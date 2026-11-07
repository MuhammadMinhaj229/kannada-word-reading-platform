import '../../../../core/config/study_protocol.dart';
import 'study_item.dart';
import 'study_item_bank.dart';

enum TrialPhase {
  practice,
  test;

  String get storageValue => name;
}

class PlannedTrial {
  const PlannedTrial({
    required this.ordinal,
    required this.phase,
    required this.phaseTrialNumber,
    required this.item,
  });

  /// One-based order in the frozen session manifest.
  final int ordinal;

  final TrialPhase phase;

  /// One-based counter within practice or test.
  final int phaseTrialNumber;

  final StudyItem item;
}

/// Immutable session order supplied by the approved study allocation.
///
/// The app validates and persists this list; it never invents or re-shuffles
/// research order at runtime.
class SessionAllocation {
  SessionAllocation({
    required this.sessionNumber,
    required this.protocolVersion,
    required this.itemBankVersion,
    required this.itemBankSha256,
    required this.protocolApprovalReference,
    required this.allocationApprovalReference,
    required List<PlannedTrial> orderedTrials,
  }) : orderedTrials = List<PlannedTrial>.unmodifiable(orderedTrials);

  final int sessionNumber;
  final String protocolVersion;
  final String itemBankVersion;
  final String itemBankSha256;
  final String protocolApprovalReference;
  final String allocationApprovalReference;
  final List<PlannedTrial> orderedTrials;

  int get practiceCount =>
      orderedTrials.where((trial) => trial.phase == TrialPhase.practice).length;

  int get testCount =>
      orderedTrials.where((trial) => trial.phase == TrialPhase.test).length;

  void validateAgainst(StudyItemBank itemBank) {
    validate();
    if (itemBank.version != itemBankVersion) {
      throw StateError(
        'Session manifest item-bank version does not match the approved bank.',
      );
    }
    itemBank.validateChecksum(itemBankSha256);
    for (final trial in orderedTrials) {
      itemBank.validateTrialItem(trial.item);
    }
  }

  void validate() {
    if (sessionNumber < 1 || sessionNumber > StudyProtocol.sessionCount) {
      throw ArgumentError.value(sessionNumber, 'sessionNumber');
    }
    if (protocolVersion.trim().isEmpty || itemBankVersion.trim().isEmpty) {
      throw ArgumentError('Protocol and item-bank versions are required.');
    }
    if (protocolApprovalReference.trim().isEmpty ||
        allocationApprovalReference.trim().isEmpty) {
      throw ArgumentError('Written approval references are required.');
    }
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(itemBankSha256)) {
      throw ArgumentError('A valid SHA-256 item-bank checksum is required.');
    }
    if (orderedTrials.length != StudyProtocol.presentationsPerSession) {
      throw ArgumentError(
        'Expected ${StudyProtocol.presentationsPerSession} presentations; '
        'received ${orderedTrials.length}.',
      );
    }
    if (practiceCount != StudyProtocol.practicePresentationsPerSession ||
        testCount != StudyProtocol.testPresentationsPerSession) {
      throw ArgumentError(
        'Session must contain the approved practice/test presentation counts.',
      );
    }

    final itemIds = <String>{};
    final itemTexts = <String>{};
    var practiceNumber = 0;
    var testNumber = 0;

    for (var index = 0; index < orderedTrials.length; index += 1) {
      final planned = orderedTrials[index];
      if (planned.ordinal != index + 1) {
        throw ArgumentError('Manifest ordinals must be sequential and unique.');
      }
      planned.item.validate();
      if (!itemIds.add(planned.item.id) ||
          !itemTexts.add(planned.item.text)) {
        throw ArgumentError('Duplicate item ID or text in the session manifest.');
      }

      switch (planned.phase) {
        case TrialPhase.practice:
          practiceNumber += 1;
          if (planned.phaseTrialNumber != practiceNumber) {
            throw ArgumentError('Practice trial numbers must be sequential.');
          }
        case TrialPhase.test:
          testNumber += 1;
          if (planned.phaseTrialNumber != testNumber) {
            throw ArgumentError('Test trial numbers must be sequential.');
          }
      }
    }
  }
}
