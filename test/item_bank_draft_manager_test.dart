import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/data/bundled_item_catalog.dart';
import 'package:padalab_android/features/assessment/data/item_bank_draft_store_contract.dart';
import 'package:padalab_android/features/assessment/domain/models/item_bank_draft.dart';
import 'package:padalab_android/features/assessor/presentation/item_bank_draft_manager.dart';

Future<void> _pumpUi(WidgetTester tester,
    [Duration duration = const Duration(milliseconds: 250)]) async {
  await tester.pump(duration);
  await tester.pump();
}

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
    tester.view.physicalSize = const Size(1200, 1800);
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
    await _pumpUi(tester);

    expect(find.textContaining('Real Words · 270'), findsOneWidget);
    expect(find.textContaining('Non-Words · 193'), findsOneWidget);

    await tester.tap(find.text('Add Real Word'));
    await _pumpUi(tester);

    await tester.enterText(find.byType(TextFormField).first, 'ಝಳಝಳದಾಖಲೆಪದ');
    await tester.tap(find.text('Save draft'));
    await _pumpUi(tester, const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Real Word draft'), findsNothing);
    expect(store.items, hasLength(1));
    final saved = store.items.values.single;
    expect(saved.text, 'ಝಳಝಳದಾಖಲೆಪದ');
    expect(saved.type, ItemBankDraftType.realWord);
    expect(saved.revision, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Non-Word draft editor exposes source provenance fields',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
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
    await _pumpUi(tester);

    await tester.tap(find.text('Add Non-Word'));
    await _pumpUi(tester);

    expect(find.text('Non-Word draft'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.text('First source word'), findsOneWidget);
    expect(find.text('First source word ID'), findsOneWidget);
    expect(find.textContaining('This saves an editable local draft only.'), findsOneWidget);

    // Defocus and close the editor deterministically. Simulating a tap on
    // the dialog action can leave the editable cursor's periodic timer alive
    // in the widget-test binding on headless CI runners.
    tester.binding.focusManager.primaryFocus?.unfocus();
    final managerContext = tester.element(find.byType(ItemBankDraftManager));
    Navigator.of(managerContext).pop();
    await _pumpUi(tester);
    expect(find.text('Non-Word draft'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('source-linked Non-Word content is persisted only after validation',
      () async {
    final store = _MemoryDraftStore();
    final draft = ItemBankDraft(
      id: 'NDRAFT-01',
      type: ItemBankDraftType.nonWord,
      text: 'ಝಳಝಳದಾಖಲೆಪದಕ',
      metadata: const <String, String>{
        'method': 'A_vowel',
        'source_word_1': 'ಮನೆ',
        'source_id_1': 'W001',
        'transformation': 'vowel transformation',
      },
    );

    final saved = await store.save(draft);

    expect(store.items, hasLength(1));
    expect(saved.type, ItemBankDraftType.nonWord);
    expect(saved.metadata['method'], 'A_vowel');
    expect(saved.metadata['source_id_1'], 'W001');
    expect(saved.revision, 1);
    expect(() => saved.validate(), returnsNormally);
  });
}
