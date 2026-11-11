import 'dart:convert';

import 'package:flutter/services.dart';

/// Engineering allocation proposal based on the latest user-confirmed ratio.
///
/// This is deliberately distinct from the signed study protocol. It can be
/// displayed and validated in the assessor workspace, but cannot open the
/// participant release gate or create participant sessions.
class AllocationProposal {
  const AllocationProposal({
    required this.version,
    required this.status,
    required this.sessionCount,
    required this.realWordsPerSession,
    required this.nonWordsPerSession,
    required this.scoredItemsPerSession,
    required this.allocatedRealWordCount,
    required this.allocatedNonWordCount,
    required this.suppliedNonWordCandidateCount,
    required this.reserveNonWordId,
    required this.participantWorkflowEnabled,
    required this.practicePolicy,
    required this.sessionDistribution,
  });

  static const String assetPath =
      'assets/item_bank/allocation_proposal_v2.json';

  final String version;
  final String status;
  final int sessionCount;
  final int realWordsPerSession;
  final int nonWordsPerSession;
  final int scoredItemsPerSession;
  final int allocatedRealWordCount;
  final int allocatedNonWordCount;
  final int suppliedNonWordCandidateCount;
  final String reserveNonWordId;
  final bool participantWorkflowEnabled;
  final String practicePolicy;
  final List<AllocationSessionCount> sessionDistribution;

  int get totalScoredItems => sessionCount * scoredItemsPerSession;

  static Future<AllocationProposal> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Allocation proposal must be a JSON object.');
    }
    return AllocationProposal.fromJson(Map<String, Object?>.from(decoded));
  }

  factory AllocationProposal.fromJson(Map<String, Object?> json) {
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported allocation proposal schema.');
    }
    final rawSessions = json['session_distribution'];
    if (rawSessions is! List) {
      throw const FormatException('Session distribution must be a list.');
    }
    final sessions = rawSessions.map((value) {
      if (value is! Map) {
        throw const FormatException('Each session distribution must be an object.');
      }
      final row = Map<String, Object?>.from(value);
      return AllocationSessionCount(
        session: _requiredInt(row, 'session'),
        realWords: _requiredInt(row, 'real_words'),
        nonWords: _requiredInt(row, 'nonwords'),
        scoredItems: _requiredInt(row, 'scored_items'),
      );
    }).toList(growable: false);

    final proposal = AllocationProposal(
      version: json['proposal_version']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      sessionCount: _requiredInt(json, 'session_count'),
      realWordsPerSession: _requiredInt(json, 'real_words_per_session'),
      nonWordsPerSession: _requiredInt(json, 'nonwords_per_session'),
      scoredItemsPerSession: _requiredInt(json, 'scored_items_per_session'),
      allocatedRealWordCount: _requiredInt(json, 'allocated_real_word_count'),
      allocatedNonWordCount: _requiredInt(json, 'allocated_nonword_count'),
      suppliedNonWordCandidateCount:
          _requiredInt(json, 'supplied_nonword_candidate_count'),
      reserveNonWordId: json['reserve_nonword_id']?.toString() ?? '',
      participantWorkflowEnabled:
          json['participant_workflow_enabled'] == true,
      practicePolicy: json['practice_policy']?.toString() ?? '',
      sessionDistribution: List<AllocationSessionCount>.unmodifiable(sessions),
    );
    proposal.validate();
    return proposal;
  }

  void validate() {
    if (version.isEmpty || status !=
        'engineering_draft_not_approved_for_participant_use') {
      throw const FormatException('Allocation proposal status is invalid.');
    }
    if (participantWorkflowEnabled) {
      throw const FormatException(
        'An engineering allocation proposal cannot enable participant workflow.',
      );
    }
    if (sessionCount != 6 || realWordsPerSession != 45 ||
        nonWordsPerSession != 32 || scoredItemsPerSession != 77) {
      throw const FormatException('Allocation proposal counts do not match 6 × (45 + 32).');
    }
    if (allocatedRealWordCount != sessionCount * realWordsPerSession ||
        allocatedNonWordCount != sessionCount * nonWordsPerSession ||
        suppliedNonWordCandidateCount != allocatedNonWordCount + 1 ||
        sessionDistribution.length != sessionCount ||
        reserveNonWordId.isEmpty) {
      throw const FormatException('Allocation proposal totals do not reconcile.');
    }
    for (var index = 0; index < sessionDistribution.length; index += 1) {
      final session = sessionDistribution[index];
      if (session.session != index + 1 ||
          session.realWords != realWordsPerSession ||
          session.nonWords != nonWordsPerSession ||
          session.scoredItems != scoredItemsPerSession ||
          session.realWords + session.nonWords != session.scoredItems) {
        throw const FormatException('A session has an invalid item allocation.');
      }
    }
    if (practicePolicy.trim().isEmpty) {
      throw const FormatException('Practice policy must be explicitly described.');
    }
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Allocation field $key must be an integer.');
    }
    return value;
  }
}

class AllocationSessionCount {
  const AllocationSessionCount({
    required this.session,
    required this.realWords,
    required this.nonWords,
    required this.scoredItems,
  });

  final int session;
  final int realWords;
  final int nonWords;
  final int scoredItems;
}
