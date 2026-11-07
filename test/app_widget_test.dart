import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('field build fails closed without a signed release', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('ASSESSOR WORKSPACE'), findsOneWidget);
    expect(find.text('Participant assessment locked'), findsOneWidget);
    expect(find.textContaining('RELEASE BLOCKERS'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Launch synthetic demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit demo build launches with fixed synthetic identifiers',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp(demoMode: true));
    expect(find.text('SYNTHETIC DEMO'), findsOneWidget);
    expect(find.text('Launch synthetic demo'), findsOneWidget);

    await tester.tap(find.text('Launch synthetic demo'));
    await tester.pumpAndSettle();

    expect(find.text('ನಮಸ್ಕಾರ!'), findsOneWidget);
    expect(find.text('ಮುಂದುವರಿಸಿ'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
