import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/data/bundled_item_catalog.dart';
import 'package:padalab_android/features/assessor/presentation/child_task_simulation_screen.dart';

Future<BundledItemCatalog> _loadRealCatalogue(WidgetTester tester) async {
  final catalogue = await tester.runAsync(() => BundledItemCatalog.load());
  if (catalogue == null) {
    throw TestFailure('The real bundled Kannada catalogue did not load.');
  }
  expect(catalogue.realWords, hasLength(270));
  expect(catalogue.suppliedNonWordCandidates, hasLength(193));
  return catalogue;
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  bool isActive = true,
  BundledItemCatalog? catalogue,
  Size viewSize = const Size(900, 900),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final loadedCatalogue = catalogue ?? await _loadRealCatalogue(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: ChildTaskSimulationScreen(
        isActive: isActive,
        catalogFuture: Future<BundledItemCatalog>.value(loadedCatalogue),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _answer(WidgetTester tester, String label) async {
  final choice = find.text(label);
  expect(choice, findsOneWidget);
  await tester.ensureVisible(choice);
  await tester.tap(choice);
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('preview loads actual supplied Kannada words instead of fixtures',
      (tester) async {
    await _pumpPreview(tester);

    expect(find.textContaining('TASK PREVIEW'), findsOneWidget);
    expect(find.text('ಬನ್ನಿ, ಪದಗಳ ಆಟ ಆಡೋಣ!'), findsOneWidget);
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('ಹೂ'), findsOneWidget);
    expect(find.text('ಕುನಮೆ'), findsNothing);
    expect(find.text('ತೊಪಲಿ'), findsNothing);
    expect(find.textContaining('ಅಭ್ಯಾಸ 1 / 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice transitions to supplied real-word and candidate preview',
      (tester) async {
    await _pumpPreview(tester);
    final startButton = find.text('ಪ್ರಾರಂಭಿಸೋಣ');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 250));

    for (var index = 0; index < 5; index += 1) {
      await _answer(tester, 'ಪದ');
    }

    // The ten-response reward cadence is not reached after five practice items.
    expect(find.text('ಚೆನ್ನಾಗಿದೆ!'), findsNothing);

    // The scored preview sequence uses actual supplied catalogue entries.
    expect(find.text('ಇಳಿ'), findsOneWidget); // source word W006
    await _answer(tester, 'ಪದ');
    expect(find.text('ಊಡು'), findsOneWidget); // supplied candidate N002
    expect(find.textContaining('ಆಟ 2 / 10'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('ಸರಿಯಾಗಿದೆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview never reveals correctness and completes without saving',
      (tester) async {
    await _pumpPreview(tester);
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pump(const Duration(milliseconds: 250));

    for (var index = 0; index < 5; index += 1) {
      await _answer(tester, 'ಪದವಲ್ಲ');
    }
    expect(find.text('ಇಳಿ'), findsOneWidget);
    expect(find.text('ಚೆನ್ನಾಗಿದೆ!'), findsNothing);

    for (var index = 0; index < 10; index += 1) {
      await _answer(tester, index.isEven ? 'ಪದ' : 'ಪದವಲ್ಲ');
      if (find.text('ಚೆನ್ನಾಗಿದೆ!').evaluate().isNotEmpty) {
        await tester.tap(find.text('ಮುಂದುವರಿಸು'));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    expect(find.text('ಅದ್ಭುತ! ಪೂರ್ವವೀಕ್ಷಣೆ ಮುಗಿದಿದೆ.'), findsOneWidget);
    expect(find.text('Word selected'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('Not word selected'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
    expect(find.textContaining('These selections are held only in this open preview.'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);
    expect(find.textContaining('ಸರಿಯಾಗಿದೆ'), findsNothing);
    expect(find.textContaining('ತಪ್ಪಾಗಿದೆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone preview keeps both answer choices reachable by touch',
      (tester) async {
    await _pumpPreview(
      tester,
      viewSize: const Size(360, 800),
    );

    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pump(const Duration(milliseconds: 250));

    for (var index = 0; index < 5; index += 1) {
      await _answer(tester, 'ಪದ');
    }

    final wordChoice = find.text('ಪದ');
    await tester.ensureVisible(wordChoice);
    await tester.tap(wordChoice);
    await tester.pump(const Duration(milliseconds: 250));

    final notWordChoice = find.text('ಪದವಲ್ಲ');
    expect(notWordChoice, findsOneWidget);
    await tester.ensureVisible(notWordChoice);
    await tester.tap(notWordChoice);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('ಆಟ 3 / 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving task preview interrupts the preview run', (tester) async {
    var active = true;
    late StateSetter updateParent;
    final catalogue = await _loadRealCatalogue(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateParent = setState;
            return ChildTaskSimulationScreen(
              isActive: active,
              catalogFuture:
                  Future<BundledItemCatalog>.value(catalogue),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('ಹೂ'), findsOneWidget);

    updateParent(() => active = false);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('ಪೂರ್ವವೀಕ್ಷಣೆ ನಿಲ್ಲಿಸಲಾಗಿದೆ'), findsOneWidget);
    expect(find.text('ಮತ್ತೆ ಪ್ರಾರಂಭಿಸಿ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
