import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';
import 'package:padalab_android/features/child/presentation/child_welcome_screen.dart';

void main() {
  testWidgets('assessor launch screen fits a narrow phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());

    expect(find.text('Prepare a child session'), findsOneWidget);
    expect(find.text('PREVIEW BUILD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child welcome screen adapts to portrait width', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
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
    await tester.pumpAndSettle();

    expect(find.text('ನಮಸ್ಕಾರ!'), findsOneWidget);
    expect(find.text('ಮುಂದುವರಿಸಿ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
