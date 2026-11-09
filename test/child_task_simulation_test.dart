import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessor/presentation/child_task_simulation_screen.dart';

Future<void> _pumpSimulation(WidgetTester tester, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    const MaterialApp(home: ChildTaskSimulationScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _answerWord(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'ಪದ');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('five practice cards transition into ten scored QA cards',
      (tester) async {
    await _pumpSimulation(tester, size: const Size(390, 844));

    expect(find.textContaining('SIMULATION ONLY'), findsOneWidget);
    expect(find.text('ಪ್ರಾರಂಭಿಸೋಣ'), findsOneWidget);

    final startButton = find.text('ಪ್ರಾರಂಭಿಸೋಣ');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('ಅಭ್ಯಾಸ'), findsOneWidget);
    expect(find.textContaining('/ 5'), findsOneWidget);
    expect(find.text('ಕುನಮೆ'), findsOneWidget);

    for (var index = 0; index < 5; index += 1) {
      await _answerWord(tester);
    }

    expect(find.textContaining('ಮುಖ್ಯ ಹಂತ'), findsOneWidget);
    expect(find.textContaining('/ 10'), findsOneWidget);
    expect(find.text('ಪೆಲುಮಿ'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);
    expect(find.textContaining('ಸರಿಯಾಗಿದೆ'), findsNothing);
    expect(find.textContaining('ತಪ್ಪಾಗಿದೆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('milestone is neutral and correctness is assessor-only',
      (tester) async {
    await _pumpSimulation(tester, size: const Size(1280, 900));

    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();

    // Ten responses include five unscored practice cards and five scored
    // simulation cards. No accuracy or correctness text is shown.
    for (var index = 0; index < 10; index += 1) {
      await _answerWord(tester);
    }

    expect(find.text('10 ಉತ್ತರಗಳು ಪೂರ್ಣಗೊಂಡಿವೆ!'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);

    await tester.tap(find.text('ಮುಂದುವರಿಸು'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 5; index += 1) {
      await _answerWord(tester);
    }

    expect(find.text('ಈ ಸಣ್ಣ ಕಾರ್ಯ ಮುಗಿದಿದೆ.'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);

    await tester.tap(find.text('Assessor results ನೋಡಿ'));
    await tester.pumpAndSettle();

    expect(find.text('Assessor QA results'), findsOneWidget);
    expect(find.text('Scored answers'), findsOneWidget);
    expect(find.text('Correct (QA key)'), findsWidgets);
    expect(find.text('Trial-by-trial inspection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
