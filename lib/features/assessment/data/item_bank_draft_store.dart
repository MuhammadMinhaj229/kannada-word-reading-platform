import 'item_bank_draft_store_contract.dart';
import 'item_bank_draft_store_stub.dart'
    if (dart.library.io) 'item_bank_draft_store_io.dart'
    if (dart.library.html) 'item_bank_draft_store_web.dart' as platform;

export 'item_bank_draft_store_contract.dart';

ItemBankDraftStore createItemBankDraftStore() => platform.createStore();
