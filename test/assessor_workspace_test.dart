import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';
import 'helpers/empty_item_bank_draft_store.dart';

Future<void> _pumpWorkspace(WidgetTester tester) async {
  await tester.pumpWidget(const PadalabApp(contentDraftStore: EmptyItemBankDraftStore()));
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
    expect(find.text('Original supplied non-word source · read-only'), findsOneWidget);
    expect(find.text('Six-session allocation proposal'), findsOneWidget);
    expect(find.text('Kannada instruction recordings'), findsOneWidget);
    expect(find.textContaining('not approved for field use'), findsOneWidget);
    expect(find.textContaining('These values are transcribed requirements only.'), findsOneWidget);
    expect(find.textContaining('demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow mobile viewport uses bottom navigation without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpWorkspace(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Application settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone portrait and landscape layouts remain usable without overflow',
    (tester) async {
  const phoneSizes = <Size>[
    Size(320, 740),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
    Size(844, 390),
  ];

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = phoneSizes.first;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await _pumpWorkspace(tester);
  for (final size in phoneSizes) {
    tester.view.physicalSize = size;
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'A ' + size.width.toInt().toString() + 'x' +
            size.height.toInt().toString() +
            ' phone layout must keep bottom navigation available.');
    expect(tester.takeException(), isNull,
        reason: 'Assessment home must not overflow at ' + size.toString() + '.');
  }

  await tester.tap(find.text('Task preview'));
  await tester.pump(const Duration(milliseconds: 350));
  for (final size in phoneSizes) {
    tester.view.physicalSize = size;
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'Task preview must not overflow at ' + size.toString() + '.');
  }

  await tester.tap(find.text('Settings'));
  await tester.pump(const Duration(milliseconds: 350));
  for (final size in phoneSizes) {
    tester.view.physicalSize = size;
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'Settings must not overflow at ' + size.toString() + '.');
  }
});

}
