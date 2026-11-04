import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/app/padalab_app.dart';

void main() {
  testWidgets('renders the Padalab assessor launch screen', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PadalabApp());

    expect(find.text('ಪದLab'), findsOneWidget);
    expect(find.text('Prepare a child session'), findsOneWidget);
  });
}
