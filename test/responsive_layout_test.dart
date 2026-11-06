import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';
import 'package:padalab_android/features/child/presentation/child_welcome_screen.dart';

void main() {
  const assessorViewports = <Size>[
    Size(320, 480),
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
    Size(600, 960),
    Size(768, 1024),
    Size(800, 1280),
    Size(844, 390),
    Size(900, 680),
    Size(1024, 600),
    Size(1024, 768),
    Size(1280, 720),
    Size(1440, 900),
    Size(1920, 1080),
  ];

  testWidgets('assessor launch adapts across phone, tablet and desktop sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in assessorViewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(const PadalabApp());
      await tester.pumpAndSettle();

      expect(find.text('Prepare a child session'), findsOneWidget,
          reason: 'Expected assessor form at $viewport');
      expect(find.text('PREVIEW BUILD'), findsOneWidget,
          reason: 'Expected preview state at $viewport');
      expect(tester.takeException(), isNull,
          reason: 'Unexpected layout exception at $viewport');
    }
  });

  testWidgets('child welcome screen adapts across common device sizes',
      (tester) async {
    const viewports = <Size>[
      Size(320, 568),
      Size(360, 780),
      Size(390, 844),
      Size(600, 960),
      Size(768, 1024),
      Size(800, 1280),
      Size(1024, 600),
      Size(1280, 720),
      Size(1920, 1080),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
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

      expect(find.text('ನಮಸ್ಕಾರ!'), findsOneWidget,
          reason: 'Expected Kannada welcome at $viewport');
      expect(find.text('ಮುಂದುವರಿಸಿ'), findsOneWidget,
          reason: 'Expected continue action at $viewport');
      expect(tester.takeException(), isNull,
          reason: 'Unexpected child layout exception at $viewport');
    }
  });
}
