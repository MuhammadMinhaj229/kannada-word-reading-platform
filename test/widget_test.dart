import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';
import 'helpers/empty_item_bank_draft_store.dart';

void main() {
  testWidgets('renders the real assessor workspace with field capture locked', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp(contentDraftStore: EmptyItemBankDraftStore()));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);
    expect(find.text('Participant sessions are locked'), findsOneWidget);
    expect(find.text('Assessor tools'), findsOneWidget);
    expect(find.text('Open item bank'), findsOneWidget);
    expect(find.text('Open task preview'), findsOneWidget);
    expect(find.text('ANDROID BUILD'), findsOneWidget);
    expect(find.text('Start assessment session'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
