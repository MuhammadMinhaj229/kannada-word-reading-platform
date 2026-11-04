import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('shows assessor workspace and protocol baseline', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('ASSESSOR WORKSPACE'), findsOneWidget);
    expect(find.text('Prepare a child session'), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
    expect(find.text('PREVIEW BUILD'), findsOneWidget);
  });

  testWidgets('requires both Child ID fields and Assessor ID', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());
    await tester.tap(find.text('Preview child experience'));
    await tester.pump();

    expect(find.text('Child ID is required.'), findsOneWidget);
    expect(find.text('Confirm Child ID is required.'), findsOneWidget);
    expect(find.text('Assessor ID is required.'), findsOneWidget);
  });
}
