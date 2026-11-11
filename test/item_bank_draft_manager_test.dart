import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/data/bundled_item_catalog.dart';
import 'package:padalab_android/features/assessment/data/item_bank_draft_store_contract.dart';
import 'package:padalab_android/features/assessment/domain/models/item_bank_draft.dart';
import 'package:padalab_android/features/assessor/presentation/item_bank_draft_manager.dart';

class _MemoryDraftStore implements ItemBankDraftStore {
  final Map<String, ItemBankDraft> items = <String, ItemBankDraft>{};
  final Map<String, List<ItemBankDraft>> history =
      <String, List<ItemBankDraft>>{};

  @override
  Future<List<ItemBankDraft>> loadAll() async =>
      List<ItemBankDraft>.unmodifiable(items.values);

  @override
  Future<ItemBankDraft> save(ItemBankDraft draft) async {
    draft.validate();
    final previous = items[draft.id];
    if ((previous?.revision ?? 0) != draft.revision) {
      throw StateError('stale draft');
    }
    if (previous != null && previous.type != draft.type) {
      throw StateError('item type changed');
    }
    if (previous != null) {
      history.putIfAbsent(draft.id, () => <ItemBankDraft>[]).add(previous);
    }
    final saved = draft.copyWith(
      revision: (previous?.revision ?? 0) + 1,
      createdAt: previous?.createdAt ?? draft.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    items[draft.id] = saved;
    return saved;
  }

  @override
  Future<List<ItemBankDraft>> loadHistory(String itemId) async =>
      List<ItemBankDraft>.unmodifiable(history[itemId] ?? const []);
}

void main() {
  testWidgets('assessor can create and persist a Real Word draft', (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = await BundledItemCatalog.load();
    final store = _MemoryDraftStore();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ItemBankDraftManager(catalog: catalog, store: store),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Real Words · 270'), findsOneWidget);
    expect(find.textContaining('Non-Words · 193'), findsOneWidget);

    await tester.tap(find.text('Add Real Word'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'ಝಳಝಳದಾಖಲೆಪದ');
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(store.items, hasLength(1));
    final saved = store.items.values.single;
    expect(saved.text, 'ಝಳಝಳದಾಖಲೆಪದ');
    expect(saved.type, ItemBankDraftType.realWord);
    expect(saved.revision, 1);
    expect(find.textContaining('Saved local draft'), findsOneWidget);

    await tester.tap(find.textContaining('Drafts · 1'));
    await tester.pumpAndSettle();
    expect(find.text('ಝಳಝಳದಾಖಲೆಪದ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assessor can create a source-linked Non-Word draft',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = await BundledItemCatalog.load();
    final store = _MemoryDraftStore();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ItemBankDraftManager(catalog: catalog, store: store),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Non-Word'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A · Vowel replacement').last);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ಝಳಝಳದಾಖಲೆಪದಕ');
    await tester.enterText(fields.at(1), 'ಮನೆ');
    await tester.enterText(fields.at(2), 'W001');
    await tester.enterText(fields.at(4), 'vowel transformation');
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(store.items, hasLength(1));
    final saved = store.items.values.single;
    expect(saved.type, ItemBankDraftType.nonWord);
    expect(saved.metadata['method'], 'A_vowel');
    expect(saved.metadata['source_id_1'], 'W001');
    expect(saved.revision, 1);
    expect(tester.takeException(), isNull);
  });
}
