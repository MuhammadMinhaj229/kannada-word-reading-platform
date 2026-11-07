import 'package:crypto/crypto.dart';
import 'package:excel_plus/excel_plus.dart';

class ImportedBankItem {
  const ImportedBankItem({
    required this.id,
    required this.text,
    required this.type,
    required this.visit,
    required this.block,
    required this.order,
    required this.nonWordMethod,
    required this.reviewerId,
    required this.reviewedAt,
  });

  final String id;
  final String text;
  final String type;
  final int visit;
  final int block;
  final int order;
  final String nonWordMethod;
  final String reviewerId;
  final String reviewedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'item_id': id,
        'item_text': text,
        'item_type': type,
        'visit_no': visit,
        'block_no': block,
        'order_no': order,
        'nonword_method': nonWordMethod,
        'reviewer_id': reviewerId,
        'reviewed_at': reviewedAt,
      };
}

class ItemBankImportResult {
  const ItemBankImportResult({
    required this.fileName,
    required this.version,
    required this.sha256,
    required this.items,
    required this.valid,
    required this.errors,
    required this.wordCount,
    required this.nonWordCount,
    required this.blockCounts,
  });

  final String fileName;
  final String version;
  final String sha256;
  final List<ImportedBankItem> items;
  final bool valid;
  final List<String> errors;
  final int wordCount;
  final int nonWordCount;
  final Map<String, ({int total, int words, int nonWords})> blockCounts;
}

/// Parses and structurally validates the same six-block workbook contract as
/// the website. This does not certify Kannada linguistic validity or create a
/// research approval: the participant release gate remains closed.
class ItemBankImportService {
  static const int maxFileBytes = 10 * 1024 * 1024;
  static const int expectedItems = 540;
  static const int expectedWords = 270;
  static const int expectedNonWords = 270;
  static const int visits = 3;
  static const int blocksPerVisit = 2;
  static const int itemsPerBlock = 90;
  static const int wordsPerBlock = 45;
  static const int nonWordsPerBlock = 45;

  static const List<String> requiredColumns = <String>[
    'item_id',
    'item_text',
    'item_type',
    'visit_no',
    'block_no',
    'order_no',
    'approval_status',
  ];

  Future<ItemBankImportResult> parse({
    required String fileName,
    required List<int> bytes,
  }) async {
    final fileHash = sha256.convert(bytes).toString();
    final bankVersion = 'sha256-${fileHash.substring(0, 16)}';
    final errors = <String>[];
    final items = <ImportedBankItem>[];

    if (bytes.isEmpty) {
      return _invalid(fileName, bankVersion, fileHash, <String>['The selected workbook is empty.']);
    }
    if (bytes.length > maxFileBytes) {
      return _invalid(
        fileName,
        bankVersion,
        fileHash,
        <String>['The workbook exceeds the 10 MB safety limit.'],
      );
    }
    if (!fileName.toLowerCase().endsWith('.xlsx')) {
      return _invalid(
        fileName,
        bankVersion,
        fileHash,
        <String>['Select an .xlsx workbook. Legacy .xls files are not accepted.'],
      );
    }

    try {
      final workbook = await Excel.decodeBytesAsync(bytes);
      final sheet = workbook.tables['Items'];
      if (sheet == null) {
        return _invalid(
          fileName,
          bankVersion,
          fileHash,
          <String>['Missing required worksheet: Items.'],
        );
      }

      if (sheet.rows.isEmpty) {
        return _invalid(
          fileName,
          bankVersion,
          fileHash,
          <String>['The Items worksheet is empty.'],
        );
      }

      final headers = <String, int>{};
      final headerRow = sheet.rows.first;
      for (var column = 0; column < headerRow.length; column += 1) {
        final header = _cellText(headerRow[column]?.value).toLowerCase();
        if (header.isNotEmpty) headers[header] = column;
      }

      final missing = requiredColumns.where((name) => !headers.containsKey(name)).toList();
      if (missing.isNotEmpty) {
        return _invalid(
          fileName,
          bankVersion,
          fileHash,
          <String>['Missing required columns: ${missing.join(', ')}.'],
        );
      }

      String readCell(List<Data?> row, String name) {
        final column = headers[name]!;
        if (column >= row.length) return '';
        return _cellText(row[column]?.value);
      }

      final ids = <String>{};
      final texts = <String>{};
      final positions = <String>{};
      var words = 0;
      var nonWords = 0;
      final mutableBlocks = <String, ({int total, int words, int nonWords})>{};

      for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex += 1) {
        final row = sheet.rows[rowIndex];
        final isBlank = row.every((cell) => _cellText(cell?.value).isEmpty);
        if (isBlank) continue;
        final rowNumber = rowIndex + 1;

        String value(String name) {
          try {
            return readCell(row, name).trim();
          } on FormatException catch (error) {
            _addError(errors, 'Row $rowNumber: ${error.message}');
            return '';
          }
        }

        final id = value('item_id');
        final text = value('item_text');
        final type = value('item_type').toLowerCase();
        final visitText = value('visit_no');
        final blockText = value('block_no');
        final orderText = value('order_no');
        final approval = value('approval_status').toLowerCase();
        final method = headers.containsKey('nonword_method') ? value('nonword_method') : '';
        final reviewer = headers.containsKey('reviewer_id') ? value('reviewer_id') : '';
        final reviewedAt = headers.containsKey('reviewed_at') ? value('reviewed_at') : '';

        final visit = int.tryParse(visitText);
        final block = int.tryParse(blockText);
        final order = int.tryParse(orderText);

        if (id.isEmpty) _addError(errors, 'Row $rowNumber: item_id is required.');
        if (text.isEmpty) _addError(errors, 'Row $rowNumber: item_text is required.');
        if (type != 'word' && type != 'nonword') {
          _addError(errors, 'Row $rowNumber: item_type must be word or nonword.');
        }
        if (approval != 'approved') {
          _addError(errors, 'Row $rowNumber: approval_status must be approved.');
        }
        if (type == 'nonword') {
          if (method.isEmpty) _addError(errors, 'Row $rowNumber: nonword_method is required.');
          if (reviewer.isEmpty) _addError(errors, 'Row $rowNumber: reviewer_id is required.');
          if (reviewedAt.isEmpty) _addError(errors, 'Row $rowNumber: reviewed_at is required.');
        }
        if (visit == null || visit < 1 || visit > visits) {
          _addError(errors, 'Row $rowNumber: visit_no must be 1, 2 or 3.');
        }
        if (block == null || block < 1 || block > blocksPerVisit) {
          _addError(errors, 'Row $rowNumber: block_no must be 1 or 2.');
        }
        if (order == null || order < 1 || order > itemsPerBlock) {
          _addError(errors, 'Row $rowNumber: order_no must be between 1 and 90.');
        }

        if (id.isNotEmpty && !ids.add(id)) {
          _addError(errors, 'Row $rowNumber: duplicate item_id "$id".');
        }
        if (text.isNotEmpty && !texts.add(text)) {
          _addError(errors, 'Row $rowNumber: duplicate item_text "$text".');
        }

        if (visit != null && block != null && order != null) {
          final blockKey = '$visit-$block';
          final positionKey = '$blockKey-$order';
          if (!positions.add(positionKey)) {
            _addError(errors, 'Row $rowNumber: duplicate position $order in block $blockKey.');
          }
          final current = mutableBlocks[blockKey] ??
              (total: 0, words: 0, nonWords: 0);
          mutableBlocks[blockKey] = (
            total: current.total + 1,
            words: current.words + (type == 'word' ? 1 : 0),
            nonWords: current.nonWords + (type == 'nonword' ? 1 : 0),
          );
        }

        if (type == 'word') {
          words += 1;
        } else if (type == 'nonword') {
          nonWords += 1;
        }

        if (id.isNotEmpty && text.isNotEmpty &&
            (type == 'word' || type == 'nonword') &&
            visit != null && block != null && order != null) {
          items.add(ImportedBankItem(
            id: id,
            text: text,
            type: type,
            visit: visit,
            block: block,
            order: order,
            nonWordMethod: method,
            reviewerId: reviewer,
            reviewedAt: reviewedAt,
          ));
        }
      }

      if (items.length != expectedItems) {
        _addError(errors, 'Expected 540 valid item rows; found ${items.length}.');
      }
      if (words != expectedWords) {
        _addError(errors, 'Expected 270 real words; found $words.');
      }
      if (nonWords != expectedNonWords) {
        _addError(errors, 'Expected 270 non-words; found $nonWords.');
      }

      for (var visit = 1; visit <= visits; visit += 1) {
        for (var block = 1; block <= blocksPerVisit; block += 1) {
          final key = '$visit-$block';
          final count = mutableBlocks[key] ?? (total: 0, words: 0, nonWords: 0);
          if (count.total != itemsPerBlock) {
            _addError(errors, 'Visit $visit, block $block: expected 90 items; found ${count.total}.');
          }
          if (count.words != wordsPerBlock) {
            _addError(errors, 'Visit $visit, block $block: expected 45 words; found ${count.words}.');
          }
          if (count.nonWords != nonWordsPerBlock) {
            _addError(errors, 'Visit $visit, block $block: expected 45 non-words; found ${count.nonWords}.');
          }
          for (var order = 1; order <= itemsPerBlock; order += 1) {
            if (!positions.contains('$key-$order')) {
              _addError(errors, 'Visit $visit, block $block: missing order $order.');
              if (errors.length >= 40) break;
            }
          }
        }
      }

      return ItemBankImportResult(
        fileName: fileName,
        version: bankVersion,
        sha256: fileHash,
        items: List<ImportedBankItem>.unmodifiable(items),
        valid: errors.isEmpty,
        errors: List<String>.unmodifiable(errors),
        wordCount: words,
        nonWordCount: nonWords,
        blockCounts: Map<String, ({int total, int words, int nonWords})>.unmodifiable(mutableBlocks),
      );
    } catch (error) {
      return _invalid(
        fileName,
        bankVersion,
        fileHash,
        <String>['Could not parse the workbook: ${error.runtimeType}. Check that it is a valid .xlsx file.'],
      );
    }
  }

  ItemBankImportResult _invalid(
    String fileName,
    String version,
    String hash,
    List<String> errors,
  ) => ItemBankImportResult(
        fileName: fileName,
        version: version,
        sha256: hash,
        items: const <ImportedBankItem>[],
        valid: false,
        errors: errors,
        wordCount: 0,
        nonWordCount: 0,
        blockCounts: const <String, ({int total, int words, int nonWords})>{},
      );

  void _addError(List<String> errors, String message) {
    if (errors.length < 40 && !errors.contains(message)) errors.add(message);
  }

  String _cellText(CellValue? value) {
    return switch (value) {
      null => '',
      TextCellValue(:final value) => value.text.trim(),
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value.toString(),
      FormulaCellValue() => throw const FormatException('Formula cells are not accepted'),
      CellErrorValue() => throw const FormatException('Excel error cells are not accepted'),
      _ => throw const FormatException('Date/time cells are not accepted in the item bank'),
    };
  }
}
