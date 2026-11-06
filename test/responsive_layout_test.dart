import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';
import 'package:padalab_android/features/child/presentation/child_welcome_screen.dart';

const _viewports = <Size>[
  // Small and common Android phones (portrait).
  Size(320, 568),
  Size(360, 640),
  Size(360, 800),
  Size(390, 844),
  Size(430, 932),
  // Small tablets and large phones (portrait).
  Size(600, 960),
  Size(768, 1024),
  Size(800, 1280),
  // Tablets and desktop browsers (landscape).
  Size(568, 320),
  Size(640, 360),
  Size(800, 600),
  Size(1024, 600),
  Size(1024, 768),
  Size(1280, 800),
  Size(1600, 900),
];

void main() {
  for (final viewport in _viewports) {
    testWidgets(
      'assessor workspace renders without overflow at '
      '${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const PadalabApp());
        await tester.pumpAndSettle();

        expect(find.text('Prepare a child session'), findsOneWidget);
        expect(find.text('PREVIEW BUILD'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'child welcome screen renders without overflow at '
      '${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: ChildWelcomeScreen(
              childId: 'DEMO-CHILD',
              assessorId: 'DEMO-ASSESSOR',
              enableDevicePresentation: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ನಮಸ್ಕಾರ!'), findsOneWidget);
        expect(find.text('ಮುಂದುವರಿಸಿ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
