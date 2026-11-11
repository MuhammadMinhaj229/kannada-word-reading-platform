import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('renders assessor tools and keeps participant sessions fail-closed',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);
    expect(find.text('Participant sessions are locked'), findsOneWidget);
    expect(find.text('Assessor tools'), findsOneWidget);
    expect(find.text('Open item bank'), findsOneWidget);
    expect(find.text('Open task preview'), findsOneWidget);
    expect(find.text('Baseline sessions'), findsNothing);
    expect(find.text('Research readiness'), findsNothing);
    expect(find.text('Required sessions'), findsNothing);
    expect(find.text('Start assessment session'), findsNothing);
    expect(find.text('Child ID'), findsNothing);
    expect(find.textContaining('demo'), findsNothing);

    await tester.tap(find.text('Open task preview'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('TASK PREVIEW'), findsOneWidget);

    await tester.tap(find.text('Assessment'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Open item bank'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Application settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
