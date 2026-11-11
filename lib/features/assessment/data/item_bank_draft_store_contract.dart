import '../domain/models/item_bank_draft.dart';

abstract interface class ItemBankDraftStore {
  Future<List<ItemBankDraft>> loadAll();
  Future<ItemBankDraft> save(ItemBankDraft draft);
  Future<List<ItemBankDraft>> loadHistory(String itemId);
}
