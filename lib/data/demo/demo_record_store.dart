import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One synthetic response from the review game. These records must never
/// contain participant IDs or be reused by the field assessment workflow.
class DemoTrialRecord {
  const DemoTrialRecord({
    required this.sessionId,
    required this.ordinal,
    required this.phase,
    required this.itemId,
    required this.stimulus,
    required this.itemKind,
    required this.response,
    required this.correct,
    required this.reactionTimeMs,
    required this.respondedAt,
  });

  final String sessionId;
  final int ordinal;
  final String phase;
  final String itemId;
  final String stimulus;
  final String itemKind;
  final String response;
  final bool correct;
  final int reactionTimeMs;
  final String respondedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'session_id': sessionId,
        'ordinal': ordinal,
        'phase': phase,
        'item_id': itemId,
        'stimulus': stimulus,
        'item_kind': itemKind,
        'response': response,
        'correct': correct,
        'reaction_time_ms': reactionTimeMs,
        'responded_at': respondedAt,
        'is_demo': true,
      };

  factory DemoTrialRecord.fromJson(Map<String, Object?> json) {
    if (json['is_demo'] != true) {
      throw const FormatException('Only synthetic demo records may be loaded.');
    }
    return DemoTrialRecord(
      sessionId: json['session_id'] as String? ?? '',
      ordinal: json['ordinal'] as int? ?? 0,
      phase: json['phase'] as String? ?? '',
      itemId: json['item_id'] as String? ?? '',
      stimulus: json['stimulus'] as String? ?? '',
      itemKind: json['item_kind'] as String? ?? '',
      response: json['response'] as String? ?? '',
      correct: json['correct'] as bool? ?? false,
      reactionTimeMs: json['reaction_time_ms'] as int? ?? 0,
      respondedAt: json['responded_at'] as String? ?? '',
    );
  }
}

/// Local persistence for review-only demo responses.
///
/// SharedPreferences is deliberately used only for synthetic demo records.
/// It is not the participant database. Real research records must use the
/// encrypted SQLCipher repository on Android and a separately reviewed
/// browser-local database adapter on Web.
class DemoRecordStore {
  DemoRecordStore._();

  static final DemoRecordStore instance = DemoRecordStore._();

  static const String _storageKey = 'padalab.synthetic-demo-records.v1';
  static const int _maxRecords = 1500;

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<DemoTrialRecord>> readAll() async {
    final payload = await _preferences.getString(_storageKey);
    if (payload == null || payload.isEmpty) return <DemoTrialRecord>[];

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! List) {
        throw const FormatException('Stored demo data is not a list.');
      }
      return decoded
          .whereType<Map>()
          .map((row) =>
              DemoTrialRecord.fromJson(Map<String, Object?>.from(row)))
          .toList(growable: false);
    } on FormatException {
      // Corrupt demo-only preferences are not silently overwritten.
      rethrow;
    } on TypeError {
      throw const FormatException('Stored demo data has an invalid schema.');
    }
  }

  Future<void> append(DemoTrialRecord record) async {
    final current = await readAll();
    final next = <DemoTrialRecord>[...current, record];
    final bounded = next.length > _maxRecords
        ? next.sublist(next.length - _maxRecords)
        : next;
    await _preferences.setString(
      _storageKey,
      jsonEncode(bounded.map((row) => row.toJson()).toList(growable: false)),
    );
  }

  Future<void> clear() => _preferences.remove(_storageKey);
}
