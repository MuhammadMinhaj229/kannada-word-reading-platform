import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';
import 'helpers/empty_item_bank_draft_store.dart';

const _viewports = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(390, 844),
  Size(430, 932),
  Size(568, 320),
  Size(600, 960),
  Size(640, 360),
  Size(768, 1024),
  Size(800, 600),
  Size(800, 1280),
  Size(1024, 600),
  Size(1024, 768),
  Size(1280, 800),
  Size(1280, 1024),
  Size(1600, 900),
];

Future<void> _pumpWorkspace(WidgetTester tester) async {
  await tester.pumpWidget(const PadalabApp(contentDraftStore: EmptyItemBankDraftStore()));
  // Avoid pumpAndSettle: the loading indicators are intentionally animated.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  for (final viewport in _viewports) {
    testWidgets(
      'assessment workspace renders at ' +
          viewport.width.toInt().toString() +
          'x' +
          viewport.height.toInt().toString(),
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpWorkspace(tester);

        expect(find.text('FIELD ASSESSMENT WORKSPACE'), findsOneWidget);
        expect(find.textContaining('demo'), findsNothing);
        expect(tester.takeException(), isNull);

        if (viewport.width >= 900) {
          expect(find.byType(NavigationRail), findsOneWidget);
        } else {
          expect(find.byType(NavigationBar), findsOneWidget);
        }
      },
    );
  }
}
