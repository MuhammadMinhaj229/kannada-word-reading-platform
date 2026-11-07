import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('renders the real assessor workspace and keeps entry fail-closed',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());
    await tester.pumpAndSettle();

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);
    expect(find.text('Participant and session entry'), findsOneWidget);
    expect(find.text('Production release requirements'), findsNothing);
    expect(find.textContaining('demo'), findsNothing);

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, isNotEmpty);
    expect(fields.every((field) => field.enabled != true), isTrue);
    expect(tester.takeException(), isNull);
  });
}
