import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/storage/browser_workspace_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('non-Web fallback loads the default workspace tab', () async {
    expect(await BrowserWorkspacePreferences.loadSelectedTab(), 0);
  });

  test('non-Web fallback ignores browser preference writes', () async {
    await expectLater(
      BrowserWorkspacePreferences.saveSelectedTab(2),
      completes,
    );
    await expectLater(
      BrowserWorkspacePreferences.saveSelectedTab(99),
      completes,
    );
  });
}
