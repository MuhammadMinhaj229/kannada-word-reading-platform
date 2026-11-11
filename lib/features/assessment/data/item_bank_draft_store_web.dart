import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../domain/models/item_bank_draft.dart';
import 'item_bank_draft_store_contract.dart';

const _databaseName = 'padalab-content-drafts-v1';
const _storeName = 'drafts';

ItemBankDraftStore createStore() => _IndexedDbItemBankDraftStore();

class _IndexedDbItemBankDraftStore implements ItemBankDraftStore {
  Future<html.IdbDatabase>? _database;

  Future<html.IdbDatabase> get _db => _database ??= _openDatabase();

  Future<html.IdbDatabase> _openDatabase() async {
    final factory = html.window.indexedDB;
    if (factory == null) {
      throw UnsupportedError('This browser does not support IndexedDB.');
    }
    final request = factory.open(_databaseName, version: 1);
    request.onUpgradeNeeded.listen((_) {
      final database = request.result as html.IdbDatabase;
      database.createObjectStore(_storeName);
    });
    final result = await _waitRequest(request);
    return result as html.IdbDatabase;
  }

  @override
  Future<List<ItemBankDraft>> loadAll() async {
    final database = await _db;
    final transaction = database.transaction(_storeName, 'readonly');
    final completed = _waitTransaction(transaction);
    try {
      final raw = await _waitRequest(
        transaction.objectStore(_storeName).getAll(),
      );
      await completed;
      if (raw is! List) {
        throw const FormatException(
          'The browser draft store returned invalid data.',
        );
      }
      final drafts = <ItemBankDraft>[];
      for (final entry in raw) {
        if (entry is! String) {
          throw const FormatException('A browser draft record is invalid.');
        }
        final decoded = jsonDecode(entry);
        if (decoded is! Map || decoded['draft'] is! Map) {
          throw const FormatException('A browser draft snapshot is missing.');
        }
        drafts.add(ItemBankDraft.fromJson(
          Map<String, Object?>.from(decoded['draft'] as Map),
        ));
      }
      drafts.sort((a, b) {
        final type = a.typeValue.compareTo(b.typeValue);
        if (type != 0) return type;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return List<ItemBankDraft>.unmodifiable(drafts);
    } catch (_) {
      try {
        await completed;
      } catch (_) {
        // Preserve the request/validation failure; the transaction also failed.
      }
      rethrow;
    }
  }

  @override
  Future<ItemBankDraft> save(ItemBankDraft draft) async {
    draft.validate();
    final database = await _db;
    final transaction = database.transaction(_storeName, 'readwrite');
    final completed = _waitTransaction(transaction);
    try {
      final store = transaction.objectStore(_storeName);
      final existingValue = await _waitRequest(store.get(draft.id));
      Map<String, Object?>? existing;
      if (existingValue is String) {
        final decoded = jsonDecode(existingValue);
        if (decoded is Map) existing = Map<String, Object?>.from(decoded);
      }
      final previousDraft = existing?['draft'];
      final previous = previousDraft is Map
          ? ItemBankDraft.fromJson(Map<String, Object?>.from(previousDraft))
          : null;
      final currentRevision = previous?.revision ?? 0;
      if (currentRevision != draft.revision) {
        throw StateError(
          'This draft changed in another browser tab. Reload it before saving.',
        );
      }
      if (previous != null && previous.type != draft.type) {
        throw StateError(
          'A draft item cannot change between Real Word and Non-Word.',
        );
      }

      final now = DateTime.now().toUtc();
      final saved = draft.copyWith(
        revision: currentRevision + 1,
        createdAt: previous?.createdAt ?? draft.createdAt,
        updatedAt: now,
      );
      final history = <Object?>[
        if (existing?['history'] is List)
          ...(existing!['history'] as List),
        if (previous != null) previous.toJson(),
      ];
      await _waitRequest(store.put(
        jsonEncode(<String, Object?>{
          'id': saved.id,
          'draft': saved.toJson(),
          'history': history,
        }),
        draft.id,
      ));
      await completed;
      return saved;
    } catch (_) {
      try {
        await completed;
      } catch (_) {
        // Preserve the original write failure.
      }
      rethrow;
    }
  }

  @override
  Future<List<ItemBankDraft>> loadHistory(String itemId) async {
    final database = await _db;
    final transaction = database.transaction(_storeName, 'readonly');
    final completed = _waitTransaction(transaction);
    try {
      final value = await _waitRequest(
        transaction.objectStore(_storeName).get(itemId),
      );
      await completed;
      if (value is! String) return const <ItemBankDraft>[];
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const <ItemBankDraft>[];
      final record = Map<String, Object?>.from(decoded);
      final revisions = <ItemBankDraft>[];
      final currentDraft = record['draft'];
      if (currentDraft is Map) {
        revisions.add(
          ItemBankDraft.fromJson(Map<String, Object?>.from(currentDraft)),
        );
      }
      final rawHistory = record['history'];
      if (rawHistory is List) {
        revisions.addAll(
          rawHistory
              .whereType<Map>()
              .map((entry) => ItemBankDraft.fromJson(
                    Map<String, Object?>.from(entry),
                  )),
        );
      }
      revisions.sort((a, b) => b.revision.compareTo(a.revision));
      return List<ItemBankDraft>.unmodifiable(revisions);
    } catch (_) {
      try {
        await completed;
      } catch (_) {
        // Preserve the request/decoding failure.
      }
      rethrow;
    }
  }
}

Future<dynamic> _waitRequest(html.IdbRequest request) {
  final completer = Completer<dynamic>();
  request.onSuccess.listen((_) {
    if (!completer.isCompleted) completer.complete(request.result);
  });
  request.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        request.error ?? StateError('IndexedDB request failed.'),
      );
    }
  });
  return completer.future;
}

Future<void> _waitTransaction(html.IdbTransaction transaction) {
  final completer = Completer<void>();
  transaction.onComplete.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  transaction.onAbort.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        transaction.error ?? StateError('IndexedDB transaction was aborted.'),
      );
    }
  });
  transaction.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        transaction.error ?? StateError('IndexedDB transaction failed.'),
      );
    }
  });
  return completer.future;
}
