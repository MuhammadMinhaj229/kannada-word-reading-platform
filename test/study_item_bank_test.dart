import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item_bank.dart';

import 'helpers/test_item_bank.dart';

void main() {
  test('validates the exact 270 real and 270 non-word requirement', () {
    final bank = createValidTestItemBank();

    expect(bank.realWordCount, 270);
    expect(bank.nonWordCount, 270);
    expect(bank.items, hasLength(540));
    expect(bank.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(() => bank.validate(), returnsNormally);
  });

  test('rejects the wrong source-item count or balance', () {
    final tooFew = createValidTestItemBank(nonWordCount: 269);
    expect(() => tooFew.validate(), throwsArgumentError);

    final unbalanced = createValidTestItemBank(
      realWordCount: 271,
      nonWordCount: 269,
    );
    expect(() => unbalanced.validate(), throwsArgumentError);
  });

  test('requires approval and native Kannada review references', () {
    final bank = createValidTestItemBank();
    final missingApproval = StudyItemBank(
      version: bank.version,
      approvedBy: '',
      approvalReference: bank.approvalReference,
      kannadaReviewReference: bank.kannadaReviewReference,
      items: bank.items,
    );

    expect(() => missingApproval.validate(), throwsArgumentError);
  });

  test('canonical checksum is independent of input row ordering', () {
    final bank = createValidTestItemBank();
    final reversed = StudyItemBank(
      version: bank.version,
      approvedBy: bank.approvedBy,
      approvalReference: bank.approvalReference,
      kannadaReviewReference: bank.kannadaReviewReference,
      items: bank.items.reversed.toList(),
    );

    expect(reversed.sha256, bank.sha256);
  });

  test('rejects content changed after checksum approval', () {
    final bank = createValidTestItemBank();
    final changedItems = List.of(bank.items);
    final original = changedItems[0];
    changedItems[0] = StudyItem(
      id: original.id,
      text: 'tampered',
      type: original.type,
      nonWordMethod: original.nonWordMethod,
    );
    final changed = StudyItemBank(
      version: bank.version,
      approvedBy: bank.approvedBy,
      approvalReference: bank.approvalReference,
      kannadaReviewReference: bank.kannadaReviewReference,
      items: changedItems,
    );

    expect(
      () => changed.validateChecksum(bank.sha256),
      throwsStateError,
    );
  });

  test('JSON import validates its embedded SHA-256', () {
    final bank = createValidTestItemBank();
    final json = bank.toJson();
    final restored = StudyItemBank.fromJson(
      jsonDecode(jsonEncode(json)) as Map<String, Object?>,
    );

    expect(restored.sha256, bank.sha256);
    expect(restored.items, hasLength(540));

    final tampered = Map<String, Object?>.from(json);
    final rawItems = (tampered['items'] as List).cast<Map<String, Object?>>();
    rawItems[0] = <String, Object?>{...rawItems[0], 'text': 'altered'};
    expect(
      () => StudyItemBank.fromJson(tampered),
      throwsStateError,
    );
  });
}
