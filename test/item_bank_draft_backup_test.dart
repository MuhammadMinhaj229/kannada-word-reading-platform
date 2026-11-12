import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/data/item_bank_draft_backup.dart';
import 'package:padalab_android/features/assessment/domain/models/item_bank_draft.dart';

ItemBankDraft _wordDraft({
  String id = 'W001',
  String text = 'ಮನೆ',
  int revision = 1,
}) {
  return ItemBankDraft(
    id: id,
    type: ItemBankDraftType.realWord,
    text: text,
    metadata: const <String, String>{
      'meaning': 'house',
      'transcription': 'mane',
    },
    revision: revision,
    createdAt: DateTime.utc(2026, 11, 12, 6),
    updatedAt: DateTime.utc(2026, 11, 12, 7),
  );
}

void main() {
  test('draft backup round trips real and non-word drafts', () {
    final word = _wordDraft();
    final nonWord = ItemBankDraft(
      id: 'N001',
      type: ItemBankDraftType.nonWord,
      text: 'ಮನೆಕ',
      metadata: const <String, String>{
        'method': 'A_vowel',
        'source_word_1': 'ಮನೆ',
        'source_id_1': 'W001',
        'transformation': 'vowel replacement',
      },
      revision: 2,
    );

    final bytes = ItemBankDraftBackup.encode([word, nonWord]);
    final restored = ItemBankDraftBackup.decode(bytes);

    expect(restored, hasLength(2));
    expect(restored[0].id, 'W001');
    expect(restored[0].text, 'ಮನೆ');
    expect(restored[0].revision, 1);
    expect(restored[1].id, 'N001');
    expect(restored[1].type, ItemBankDraftType.nonWord);
    expect(restored[1].metadata['source_id_1'], 'W001');
  });

  test('backup is explicitly marked as not approved for gameplay', () {
    final payload = jsonDecode(
      utf8.decode(ItemBankDraftBackup.encode([_wordDraft()])),
    ) as Map<String, Object?>;
    expect(payload['approved_for_gameplay'], isFalse);
  });

  test('rejects a backup marked as approved for gameplay', () {
    final payload = <String, Object?>{
      'schema_version': 1,
      'application': 'PadLab content drafts',
      'approved_for_gameplay': true,
      'items': <Object?>[],
    };
    expect(
      () => ItemBankDraftBackup.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      ),
      throwsFormatException,
    );
  });

  test('rejects duplicate item IDs', () {
    final draft = _wordDraft().toJson();
    final payload = <String, Object?>{
      'schema_version': 1,
      'application': 'PadLab content drafts',
      'approved_for_gameplay': false,
      'items': <Object?>[draft, draft],
    };
    expect(
      () => ItemBankDraftBackup.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      ),
      throwsFormatException,
    );
  });

  test('rejects backups above the size limit', () {
    final bytes = Uint8List(ItemBankDraftBackup.maxBytes + 1);
    expect(
      () => ItemBankDraftBackup.decode(bytes),
      throwsFormatException,
    );
  });
}
