import 'dart:convert';

import '../../../data/database/assessment_database.dart';
import '../domain/models/item_bank_draft.dart';
import 'item_bank_draft_store_contract.dart';

ItemBankDraftStore createStore() => _SqlCipherItemBankDraftStore();

class _SqlCipherItemBankDraftStore implements ItemBankDraftStore {
  final AssessmentDatabase _database = AssessmentDatabase();

  @override
  Future<List<ItemBankDraft>> loadAll() async {
    final rows = await _database.loadContentDraftItems();
    return rows.map(ItemBankDraft.fromJson).toList(growable: false);
  }

  @override
  Future<ItemBankDraft> save(ItemBankDraft draft) async {
    draft.validate();
    final row = await _database.saveContentDraftItem(
      itemId: draft.id,
      itemType: draft.typeValue,
      itemText: draft.text,
      metadataJson: jsonEncode(draft.metadata),
      expectedRevision: draft.revision,
    );
    return ItemBankDraft.fromJson(row);
  }

  @override
  Future<List<ItemBankDraft>> loadHistory(String itemId) async {
    final rows = await _database.loadContentDraftHistory(itemId);
    return rows.map(ItemBankDraft.fromJson).toList(growable: false);
  }
}
