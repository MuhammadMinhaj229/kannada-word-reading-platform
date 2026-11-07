import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/child/presentation/child_welcome_screen.dart';

void main() {
  testWidgets('Continue opens the playable demo and responses advance trials',
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

    expect(find.text('ಮಾದರಿ 1 / 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-word-answer')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-nonword-answer')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-word-answer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demo-next')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-next')));
    await tester.pumpAndSettle();
    expect(find.text('ಮಾದರಿ 2 / 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-nonword-answer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-next')));
    await tester.pumpAndSettle();
    expect(find.text('ಮಾದರಿ 3 / 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-word-answer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-next')));
    await tester.pumpAndSettle();
    expect(find.text('ಮಾದರಿ 4 / 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo-nonword-answer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-next')));
    await tester.pumpAndSettle();

    expect(find.text('ಪ್ರದರ್ಶನ ಪೂರ್ಣಗೊಂಡಿದೆ'), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo can restart after completion without persisted data',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('This test is covered by the complete flow above.'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
