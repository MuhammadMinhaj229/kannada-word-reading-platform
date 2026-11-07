import 'dart:convert';
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:file_saver/file_saver.dart';

import '../../../data/demo/demo_record_store.dart';

class DemoExportResult {
  const DemoExportResult({
    required this.fileName,
    required this.recordCount,
  });

  final String fileName;
  final int recordCount;
}

/// Exports only synthetic review-game responses. It intentionally has no
/// participant identifier filter or participant-data export path.
class DemoExportService {
  Future<DemoExportResult> exportCsv() async {
    final records = await DemoRecordStore.instance.readAll();
    if (records.isEmpty) {
      throw StateError('There are no saved demo responses to export yet.');
    }

    const fields = <String>[
      'session_id',
      'ordinal',
      'phase',
      'item_id',
      'stimulus',
      'item_kind',
      'response',
      'correct',
      'reaction_time_ms',
      'responded_at',
      'is_demo',
    ];

    final output = StringBuffer()..writeln(fields.map(_csvCell).join(','));
    for (final record in records) {
      final row = record.toJson();
      output.writeln(fields.map((field) => _csvCell(row[field])).join(','));
    }

    final payload = utf8.encode(output.toString());
    final bytes = Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...payload]);
    final fileName = 'padalab-demo-responses';
    await FileSaver.instance.saveAs(
      name: fileName,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.other,
    );
    return DemoExportResult(fileName: '$fileName.csv', recordCount: records.length);
  }

  Future<DemoExportResult> exportXlsx() async {
    final records = await DemoRecordStore.instance.readAll();
    if (records.isEmpty) {
      throw StateError('There are no saved demo responses to export yet.');
    }

    final workbook = Excel.createExcel();
    final trials = workbook['Trials'];
    trials.appendRow(<CellValue?>[
      TextCellValue('Session ID'),
      TextCellValue('Ordinal'),
      TextCellValue('Phase'),
      TextCellValue('Item ID'),
      TextCellValue('Stimulus'),
      TextCellValue('Item Type'),
      TextCellValue('Response'),
      TextCellValue('Matched'),
      TextCellValue('Reaction Time (ms)'),
      TextCellValue('Responded At'),
      TextCellValue('Demo Record'),
    ]);

    for (final record in records) {
      trials.appendRow(<CellValue?>[
        TextCellValue(record.sessionId),
        IntCellValue(record.ordinal),
        TextCellValue(record.phase),
        TextCellValue(record.itemId),
        TextCellValue(record.stimulus),
        TextCellValue(record.itemKind),
        TextCellValue(record.response),
        BoolCellValue(record.correct),
        IntCellValue(record.reactionTimeMs),
        TextCellValue(record.respondedAt),
        const BoolCellValue(true),
      ]);
    }

    final summary = workbook['Export Info'];
    summary.appendRow(<CellValue?>[
      TextCellValue('Exported at'),
      TextCellValue(DateTime.now().toUtc().toIso8601String()),
    ]);
    summary.appendRow(<CellValue?>[
      TextCellValue('Demo records'),
      IntCellValue(records.length),
    ]);
    summary.appendRow(<CellValue?>[
      TextCellValue('Data source'),
      TextCellValue('This device/browser synthetic demo storage'),
    ]);
    summary.appendRow(<CellValue?>[
      TextCellValue('Research status'),
      TextCellValue('Demo only — not participant research data'),
    ]);

    workbook.delete('Sheet1');
    final encoded = await workbook.encodeAsync();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('The Excel workbook could not be encoded.');
    }

    const fileName = 'padalab-demo-responses';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(encoded),
      fileExtension: 'xlsx',
      mimeType: MimeType.other,
    );
    return DemoExportResult(fileName: '$fileName.xlsx', recordCount: records.length);
  }

  String _csvCell(Object? value) {
    var text = value == null ? '' : value.toString();
    // Prevent exported values from becoming spreadsheet formulas.
    if (RegExp(r'^\s*[=+@-]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }
}
