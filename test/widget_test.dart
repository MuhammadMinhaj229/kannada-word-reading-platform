import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('renders the real assessor workspace by default', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());
    await tester.pumpAndSettle();

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);
    expect(find.text('Participant and session entry'), findsOneWidget);
    expect(find.text('FIELD RELEASE GATED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
