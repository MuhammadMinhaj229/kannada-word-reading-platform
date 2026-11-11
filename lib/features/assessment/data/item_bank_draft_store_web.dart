import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/models/item_bank_draft.dart';
import 'item_bank_draft_store_contract.dart';

const _databaseName = 'padalab-content-drafts-v1';
const _storeName = 'drafts';

ItemBankDraftStore createStore() => _IndexedDbItemBankDraftStore();

class _IndexedDbItemBankDraftStore implements ItemBankDraftStore {
  Future<web.IDBDatabase>? _database;

  Future<web.IDBDatabase> get _db => _database ??= _openDatabase();

  Future<web.IDBDatabase> _openDatabase() async {
    final request = web.window.indexedDB.open(_databaseName, 1);
    request.addEventListener(
      'upgradeneeded',
      ((web.Event event) {
        final database = request.result as web.IDBDatabase;
        database.createObjectStore(_storeName);
      }).toJS,
    );
    final result = await _waitRequest(request);
    return result as web.IDBDatabase;
  }

  @override
  Future<List<ItemBankDraft>> loadAll() async {
    final database = await _db;
    final transaction = database.transaction(_jsString(_storeName), _jsString('readonly'));
    final completed = _waitTransaction(transaction);
    try {
      final raw = (await _waitRequest(
        transaction.objectStore(_storeName).getAll(),
      )).dartify();
      await completed;
      if (raw is! List) {
        throw const FormatException(
          'The browser draft store returned invalid data.',
        );
      }
      final drafts = raw.map((value) {
        if (value is! String) {
          throw const FormatException('A browser draft record is invalid.');
        }
        final decoded = jsonDecode(value);
        if (decoded is! Map || decoded['draft'] is! Map) {
          throw const FormatException('A browser draft snapshot is missing.');
        }
        return ItemBankDraft.fromJson(
          Map<String, Object?>.from(decoded['draft'] as Map),
        );
      }).toList(growable: false);
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
        // Preserve the original request or validation failure.
      }
      rethrow;
    }
  }

  @override
  Future<ItemBankDraft> save(ItemBankDraft draft) async {
    draft.validate();
    final database = await _db;
    final transaction = database.transaction(_jsString(_storeName), _jsString('readwrite'));
    final completed = _waitTransaction(transaction);
    try {
      final store = transaction.objectStore(_storeName);
      final existingValue = (await _waitRequest(
        store.get(_jsString(draft.id)),
      )).dartify();
      Map<String, Object?>? existing;
      if (existingValue is String) {
        final decoded = jsonDecode(existingValue);
        if (decoded is Map) {
          existing = Map<String, Object?>.from(decoded);
        }
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

      final saved = draft.copyWith(
        revision: currentRevision + 1,
        createdAt: previous?.createdAt ?? draft.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      final history = <Object?>[
        if (existing?['history'] is List)
          ...(existing!['history'] as List),
        if (previous != null) previous.toJson(),
      ];
      await _waitRequest(store.put(
        jsonEncode(<String, Object?>{
          'draft': saved.toJson(),
          'history': history,
        }).toJS,
        _jsString(draft.id),
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
      final value = (await _waitRequest(
        transaction.objectStore(_storeName).get(_jsString(itemId)),
      )).dartify();
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
        // Preserve the original request or decoding failure.
      }
      rethrow;
    }
  }
}

Future<JSAny?> _waitRequest(web.IDBRequest request) {
  final completer = Completer<JSAny?>();
  request.addEventListener(
    'success',
    ((web.Event event) {
      if (!completer.isCompleted) completer.complete(request.result);
    }).toJS,
  );
  request.addEventListener(
    'error',
    ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(
          request.error ?? StateError('IndexedDB request failed.'),
        );
      }
    }).toJS,
  );
  return completer.future;
}

Future<void> _waitTransaction(web.IDBTransaction transaction) {
  final completer = Completer<void>();
  transaction.addEventListener(
    'complete',
    ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS,
  );
  transaction.addEventListener(
    'abort',
    ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(
          transaction.error ?? StateError('IndexedDB transaction was aborted.'),
        );
      }
    }).toJS,
  );
  return completer.future;
}

JSAny _jsString(String value) => value.toJS as JSAny;
