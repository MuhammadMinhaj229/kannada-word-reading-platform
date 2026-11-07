import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('renders the participant-safe release lock by default',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('Participant assessment locked'), findsOneWidget);
    expect(find.textContaining('Written PI/statistician approval'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
