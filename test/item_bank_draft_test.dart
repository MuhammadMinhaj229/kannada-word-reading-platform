import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/item_bank_draft.dart';

void main() {
  test('round trips a Real Word draft with metadata and revision', () {
    final draft = ItemBankDraft(
      id: 'W001',
      type: ItemBankDraftType.realWord,
      text: 'ಮನೆ',
      metadata: const <String, String>{
        'meaning': 'house',
        'transcription': 'mane',
      },
      revision: 3,
    );

    final restored = ItemBankDraft.fromJson(draft.toJson());
    expect(restored.id, draft.id);
    expect(restored.type, ItemBankDraftType.realWord);
    expect(restored.text, 'ಮನೆ');
    expect(restored.metadata['meaning'], 'house');
    expect(restored.revision, 3);
  });

  test('requires source provenance for Non-Word drafts', () {
    final draft = ItemBankDraft(
      id: 'N001',
      type: ItemBankDraftType.nonWord,
      text: 'ಮನೆಕ',
      metadata: const <String, String>{
        'method': 'A_vowel',
        'source_word_1': 'ಮನೆ',
        'source_id_1': 'W001',
        'transformation': 'vowel replacement',
      },
    );
    expect(draft.validate, returnsNormally);
  });

  test('rejects Non-Word drafts without source provenance', () {
    final draft = ItemBankDraft(
      id: 'N002',
      type: ItemBankDraftType.nonWord,
      text: 'ಮನೆಕ',
      metadata: const <String, String>{'method': 'A_vowel'},
    );
    expect(draft.validate, throwsArgumentError);
  });

  test('requires the second source for two-source Non-Word methods', () {
    final draft = ItemBankDraft(
      id: 'N003',
      type: ItemBankDraftType.nonWord,
      text: 'ಮನೆಕ',
      metadata: const <String, String>{
        'method': 'C_suffix_prefix',
        'source_word_1': 'ಮನೆ',
        'source_id_1': 'W001',
        'transformation': 'blend',
      },
    );
    expect(draft.validate, throwsArgumentError);
  });
}
