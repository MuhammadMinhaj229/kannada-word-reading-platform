import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    await tester.ensureVisible(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data?.startsWith('ಅಭ್ಯಾಸ') == true &&
            widget.data?.contains('/ 5') == true,
      ),
      findsOneWidget,
    );
    expect(find.text('ಕುನಮೆ'), findsOneWidget);

    for (var index = 0; index < 5; index += 1) {
      await _answerWord(tester);
    }

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data?.startsWith('ಮುಖ್ಯ ಹಂತ') == true &&
            widget.data?.contains('/ 10') == true,
      ),
      findsOneWidget,
    );
    expect(find.text('ಪೆಲುಮಿ'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);
    expect(find.textContaining('ಸರಿಯಾಗಿದೆ'), findsNothing);
    expect(find.textContaining('ತಪ್ಪಾಗಿದೆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stimulus and response controls are available in the first rendered frame',
      (tester) async {
    await _pumpSimulation(tester, size: const Size(1280, 900));

    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pump();

    expect(find.text('ಕುನಮೆ'), findsOneWidget);
    final wordChoice = find.widgetWithText(FilledButton, 'ಪದ');
    expect(tester.widget<FilledButton>(wordChoice).onPressed, isNotNull);

    // The post-frame stopwatch has started by the time the first stimulus
    // frame completes, so an immediate response is accepted without waiting
    // for a second frame to enable the choice controls.
    await tester.tap(wordChoice);
    await tester.pump();

    expect(find.text('ತೊಪಲಿ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('milestone is neutral and correctness is assessor-only',
      (tester) async {
    await _pumpSimulation(tester, size: const Size(1280, 900));

    await tester.ensureVisible(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
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

  testWidgets('discards the current run when the app is backgrounded',
      (tester) async {
    await _pumpSimulation(tester, size: const Size(800, 600));

    await tester.ensureVisible(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();
    expect(find.text('ಕುನಮೆ'), findsOneWidget);

    // Test bindings may already start in paused state. Drive a complete
    // resume -> background transition so the second message is observable.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(
        AppLifecycleState.resumed.toString(),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(
        AppLifecycleState.paused.toString(),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('QA run interrupted'), findsOneWidget);
    expect(find.text('Restart QA run'), findsOneWidget);
    expect(find.text('ಪೆಲುಮಿ'), findsNothing);

    // The assessor can interact with the app only after it becomes active.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(
        AppLifecycleState.resumed.toString(),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restart QA run'));
    await tester.pumpAndSettle();

    expect(find.text('ಪ್ರಾರಂಭಿಸೋಣ'), findsOneWidget);
    expect(find.text('QA run interrupted'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discards the current run when assessor leaves Task preview',
      (tester) async {
    var isActive = true;
    late StateSetter updateParent;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateParent = setState;
            return ChildTaskSimulationScreen(isActive: isActive);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.tap(find.text('ಪ್ರಾರಂಭಿಸೋಣ'));
    await tester.pumpAndSettle();
    expect(find.text('ಕುನಮೆ'), findsOneWidget);

    updateParent(() => isActive = false);
    await tester.pumpAndSettle();

    expect(find.text('QA run interrupted'), findsOneWidget);
    expect(find.text('Restart QA run'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
