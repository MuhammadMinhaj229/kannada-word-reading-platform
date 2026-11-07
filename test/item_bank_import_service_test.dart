import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/data/item_bank_import_service.dart';

Future<Uint8List> _buildWorkbook({
  String approvalStatus = 'approved',
  bool includeReviewerMetadata = true,
}) async {
  final workbook = Excel.createExcel();
  final sheet = workbook['Items'];
  sheet.appendRow(<CellValue?>[
    TextCellValue('item_id'),
    TextCellValue('item_text'),
    TextCellValue('item_type'),
    TextCellValue('visit_no'),
    TextCellValue('block_no'),
    TextCellValue('order_no'),
    TextCellValue('approval_status'),
    TextCellValue('nonword_method'),
    TextCellValue('reviewer_id'),
    TextCellValue('reviewed_at'),
  ]);

  for (var visit = 1; visit <= 3; visit += 1) {
    for (var block = 1; block <= 2; block += 1) {
      for (var order = 1; order <= 90; order += 1) {
        final isWord = order.isOdd;
        sheet.appendRow(<CellValue?>[
          TextCellValue('KWR-V$visit-B$block-${order.toString().padLeft(3, '0')}'),
          TextCellValue(isWord ? 'ಕನ್ನಡಪದ$visit$block$order' : 'ಕಲ್ಪಿತ$visit$block$order'),
          TextCellValue(isWord ? 'word' : 'nonword'),
          IntCellValue(visit),
          IntCellValue(block),
          IntCellValue(order),
          TextCellValue(approvalStatus),
          TextCellValue(isWord ? '' : 'native-review-candidate'),
          TextCellValue(!isWord && includeReviewerMetadata ? 'reviewer-01' : ''),
          TextCellValue(!isWord && includeReviewerMetadata ? '2026-11-01' : ''),
        ]);
      }
    }
  }

  final bytes = await workbook.encodeAsync();
  if (bytes == null) throw StateError('Could not encode test workbook.');
  return Uint8List.fromList(bytes);
}

void main() {
  test('accepts a structurally valid 540-row six-block workbook', () async {
    final bytes = await _buildWorkbook();
    final result = await ItemBankImportService().parse(
      fileName: 'approved-items.xlsx',
      bytes: bytes,
    );

    expect(result.valid, isTrue, reason: result.errors.join('\n'));
    expect(result.items, hasLength(540));
    expect(result.wordCount, 270);
    expect(result.nonWordCount, 270);
    expect(result.blockCounts, hasLength(6));
    expect(result.sha256, hasLength(64));
    expect(result.version, startsWith('sha256-'));
  });

  test('rejects workbook rows that are not marked approved', () async {
    final bytes = await _buildWorkbook(approvalStatus: 'pending');
    final result = await ItemBankImportService().parse(
      fileName: 'pending-items.xlsx',
      bytes: bytes,
    );

    expect(result.valid, isFalse);
    expect(
      result.errors.any((error) => error.contains('approval_status must be approved')),
      isTrue,
    );
  });

  test('rejects non-words without native reviewer metadata', () async {
    final bytes = await _buildWorkbook(includeReviewerMetadata: false);
    final result = await ItemBankImportService().parse(
      fileName: 'unreviewed-items.xlsx',
      bytes: bytes,
    );

    expect(result.valid, isFalse);
    expect(
      result.errors.any((error) => error.contains('reviewer_id is required')),
      isTrue,
    );
  });

  test('rejects oversized workbooks before parsing', () async {
    final bytes = Uint8List(ItemBankImportService.maxFileBytes + 1);
    final result = await ItemBankImportService().parse(
      fileName: 'oversized.xlsx',
      bytes: bytes,
    );

    expect(result.valid, isFalse);
    expect(result.errors.single, contains('10 MB safety limit'));
  });

  test('rejects a missing Items worksheet', () async {
    final workbook = Excel.createExcel();
    final bytes = Uint8List.fromList(workbook.save()!);
    final result = await ItemBankImportService().parse(
      fileName: 'wrong-sheet.xlsx',
      bytes: bytes,
    );

    expect(result.valid, isFalse);
    expect(result.errors.single, contains('Items'));
  });
}
