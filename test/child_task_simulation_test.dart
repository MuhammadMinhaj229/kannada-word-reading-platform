import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessor/presentation/child_task_simulation_screen.dart';

Future<void> _pumpPreview(WidgetTester tester, {bool isActive = true}) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: ChildTaskSimulationScreen(isActive: isActive)),
  );
  await tester.pumpAndSettle();
}

Future<void> _answer(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('preview loads actual supplied Kannada words instead of fixtures',
      (tester) async {
    await _pumpPreview(tester);

    expect(find.textContaining('TASK PREVIEW'), findsOneWidget);
    expect(find.text('ಬನ್ನಿ, ಪದಗಳ ಆಟ ಆಡೋಣ!'), findsOneWidget);
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();

    expect(find.text('ಹೂ'), findsOneWidget);
    expect(find.text('ಕುನಮೆ'), findsNothing);
    expect(find.text('ತೊಪಲಿ'), findsNothing);
    expect(find.textContaining('ಅಭ್ಯಾಸ 1 / 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice transitions to supplied real-word and candidate preview',
      (tester) async {
    await _pumpPreview(tester);
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 5; index += 1) {
      await _answer(tester, 'ಪದ');
    }

    expect(find.text('ಚೆನ್ನಾಗಿದೆ!'), findsOneWidget);
    await tester.tap(find.text('ಮುಂದುವರಿಸು'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    for (var index = 0; index < 5; index += 1) {
      await _answer(tester, 'ಪದವಲ್ಲ');
    }
    await tester.tap(find.text('ಮುಂದುವರಿಸು'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 10; index += 1) {
      await _answer(tester, index.isEven ? 'ಪದ' : 'ಪದವಲ್ಲ');
      if (find.text('ಚೆನ್ನಾಗಿದೆ!').evaluate().isNotEmpty) {
        await tester.tap(find.text('ಮುಂದುವರಿಸು'));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('ಅದ್ಭುತ! ಪೂರ್ವವೀಕ್ಷಣೆ ಮುಗಿದಿದೆ.'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);
    expect(find.textContaining('ಸರಿಯಾಗಿದೆ'), findsNothing);
    expect(find.textContaining('ತಪ್ಪಾಗಿದೆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving task preview interrupts the preview run', (tester) async {
    var active = true;
    late StateSetter updateParent;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateParent = setState;
            return ChildTaskSimulationScreen(isActive: active);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();
    expect(find.text('ಹೂ'), findsOneWidget);

    updateParent(() => active = false);
    await tester.pumpAndSettle();

    expect(find.text('ಪೂರ್ವವೀಕ್ಷಣೆ ನಿಲ್ಲಿಸಲಾಗಿದೆ'), findsOneWidget);
    expect(find.text('ಮತ್ತೆ ಪ್ರಾರಂಭಿಸಿ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
