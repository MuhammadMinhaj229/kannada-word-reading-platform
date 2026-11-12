import 'package:padalab_android/features/assessment/data/item_bank_draft_store_contract.dart';
import 'package:padalab_android/features/assessment/domain/models/item_bank_draft.dart';

/// Explicit no-I/O adapter for widget tests that render the full app shell.
/// Persistence behaviour is tested separately against SQLCipher and IndexedDB.
class EmptyItemBankDraftStore implements ItemBankDraftStore {
  const EmptyItemBankDraftStore();

  @override
  Future<List<ItemBankDraft>> loadAll() async => const <ItemBankDraft>[];

  @override
  Future<ItemBankDraft> save(ItemBankDraft draft) =>
      Future<ItemBankDraft>.error(
        UnsupportedError('This test adapter does not support writes.'),
      );

  @override
  Future<List<ItemBankDraft>> loadHistory(String itemId) async =>
      const <ItemBankDraft>[];
}
