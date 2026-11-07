import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:file_saver/file_saver.dart';

class ItemBankTemplateService {
  Future<void> downloadTemplate() async {
    final workbook = Excel.createExcel();
    final items = workbook['Items'];
    items.appendRow(<CellValue?>[
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
          final itemType = order.isOdd ? 'word' : 'nonword';
          items.appendRow(<CellValue?>[
            TextCellValue(
              'KWR-V$visit-B$block-${order.toString().padLeft(3, '0')}',
            ),
            TextCellValue(''),
            TextCellValue(itemType),
            IntCellValue(visit),
            IntCellValue(block),
            IntCellValue(order),
            TextCellValue('pending'),
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
          ]);
        }
      }
    }

    final instructions = workbook['Instructions'];
    instructions.appendRow(<CellValue?>[
      TextCellValue('Field'),
      TextCellValue('Instruction'),
    ]);
    const guidance = <List<String>>[
      <String>['Purpose', 'Authoring template only. This is not an approved item bank.'],
      <String>['Allocation', '3 visits × 2 blocks × 90 scored items = 540 rows.'],
      <String>['Balance', 'Each block requires exactly 45 real words and 45 non-words.'],
      <String>['Order', 'Alternating word/non-word slots are placeholders, not an approved randomisation order.'],
      <String>['Practice', 'Five practice items are outside this scored-item workbook; the PI must confirm how they are sourced.'],
      <String>['Approval', 'Set approval_status to approved only after documented research-team approval.'],
      <String>['Non-word review', 'Complete nonword_method, reviewer_id and reviewed_at for every non-word.'],
      <String>['Linguistic quality', 'Structural checks cannot certify Kannada linguistic validity. Native reviewer sign-off is required.'],
      <String>['Privacy', 'Do not include child names or participant data in this authoring workbook.'],
    ];
    for (final row in guidance) {
      instructions.appendRow(<CellValue?>[
        TextCellValue(row[0]),
        TextCellValue(row[1]),
      ]);
    }

    workbook.delete('Sheet1');
    final bytes = await workbook.encodeAsync();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('The item-bank template could not be encoded.');
    }

    await FileSaver.instance.saveAs(
      name: 'kannada-item-bank-template',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.other,
    );
  }
}
