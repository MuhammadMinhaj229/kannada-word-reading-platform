import '../domain/models/item_bank_draft.dart';
import 'item_bank_draft_store_contract.dart';

ItemBankDraftStore createStore() => _UnsupportedDraftStore();

class _UnsupportedDraftStore implements ItemBankDraftStore {
  @override
  Future<List<ItemBankDraft>> loadAll() async => const <ItemBankDraft>[];

  @override
  Future<ItemBankDraft> save(ItemBankDraft draft) async {
    throw UnsupportedError('Content drafts are unavailable on this platform.');
  }

  @override
  Future<List<ItemBankDraft>> loadHistory(String itemId) async =>
      const <ItemBankDraft>[];
}
