import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('Game is the default tab and Settings is the second tab',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp(demoMode: true));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ಆಟ ಪ್ರಾರಂಭಿಸಿ'), findsOneWidget);
    expect(find.text('Assessor settings'), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Assessor settings'), findsOneWidget);
    expect(find.text('Kannada voice preview'), findsOneWidget);
    expect(find.text('Item bank'), findsOneWidget);
    expect(find.text('Reports and export'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Game'));
    await tester.pumpAndSettle();

    expect(find.text('ಆಟ ಪ್ರಾರಂಭಿಸಿ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field Settings does not enable demo voice or participant entry',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final voiceSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Automatic Kannada voice preview'),
    );
    expect(voiceSwitch.onChanged, isNull);
    expect(find.text('No participant data is collected'), findsOneWidget);
    expect(find.text('FIELD RELEASE LOCKED · DO NOT USE WITH PARTICIPANTS'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
