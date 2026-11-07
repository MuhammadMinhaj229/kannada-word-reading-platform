import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

Future<void> _pumpWorkspace(WidgetTester tester) async {
  await tester.pumpWidget(const PadalabApp());
  // The assessor workspace contains indeterminate loading indicators while
  // local assets are being read, so pump fixed frames instead of settling.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  testWidgets('wide tablet uses the responsive navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpWorkspace(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Application settings'), findsOneWidget);
    expect(find.text('Supplied Kannada item bank'), findsOneWidget);
    expect(find.text('Kannada instruction recordings'), findsOneWidget);
    expect(find.textContaining('demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow mobile viewport uses bottom navigation without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Kannada word-reading'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Supplied Kannada item bank'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
