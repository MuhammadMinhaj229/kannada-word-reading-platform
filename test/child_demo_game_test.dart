import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padalab_android/features/child/presentation/child_welcome_screen.dart';
import 'package:padalab_android/features/child/presentation/demo_game_screen.dart';

Future<void> _answerCurrentDemoItem(
  WidgetTester tester, {
  required int globalIndex,
}) async {
  // The five synthetic practice examples are all words. The ten scored-demo
  // examples alternate word/non-word exactly like the website review flow.
  final isWord = globalIndex < 5 || (globalIndex - 5).isEven;
  await tester.tap(
    find.byKey(
      ValueKey(isWord ? 'demo-word-answer' : 'demo-nonword-answer'),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('demo-next')));
  await tester.pumpAndSettle();

  // A sample reward pauses after every five scored-demo responses.
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    expect(find.textContaining('sample reward only'), findsOneWidget);
    await tester.tap(find.text('ಮುಂದುವರಿಸಿ'));
    await tester.pumpAndSettle();
  }
}

Future<void> _completeDemo(WidgetTester tester) async {
  for (var index = 0; index < 15; index += 1) {
    await _answerCurrentDemoItem(tester, globalIndex: index);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Continue opens the 5-practice plus 10-scored website demo flow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ChildWelcomeScreen(
          childId: 'DEMO-CHILD',
          assessorId: 'DEMO-ASSESSOR',
          enableDevicePresentation: false,
        ),
      ),
    );

    await tester.tap(find.text('ಮುಂದುವರಿಸಿ'));
    await tester.pumpAndSettle();

    expect(find.text('ಅಭ್ಯಾಸ 1 / 5'), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-word-answer')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-nonword-answer')), findsOneWidget);

    await _answerCurrentDemoItem(tester, globalIndex: 0);
    expect(find.text('ಅಭ್ಯಾಸ 2 / 5'), findsOneWidget);

    for (var index = 1; index < 5; index += 1) {
      await _answerCurrentDemoItem(tester, globalIndex: index);
    }

    expect(find.text('ಪರೀಕ್ಷೆ 1 / 10'), findsOneWidget);

    for (var index = 5; index < 15; index += 1) {
      await _answerCurrentDemoItem(tester, globalIndex: index);
    }

    expect(find.text('ಪ್ರದರ್ಶನ ಪೂರ್ಣಗೊಂಡಿದೆ'), findsOneWidget);
    expect(find.text('15 / 15'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed demo can restart from the first practice item',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DemoGameScreen()),
    );

    await _completeDemo(tester);
    expect(find.text('ಪ್ರದರ್ಶನ ಪೂರ್ಣಗೊಂಡಿದೆ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-restart')));
    await tester.pumpAndSettle();

    expect(find.text('ಅಭ್ಯಾಸ 1 / 5'), findsOneWidget);
    expect(find.text('ಪ್ರದರ್ಶನ ಪೂರ್ಣಗೊಂಡಿದೆ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
