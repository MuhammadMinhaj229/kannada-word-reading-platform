import 'browser_workspace_preferences_stub.dart'
    if (dart.library.html) 'browser_workspace_preferences_web.dart'
    as implementation;

/// Small, non-sensitive browser workspace preferences.
///
/// This adapter is intentionally not a participant-data store. Structured
/// Web-local records require a separate IndexedDB implementation and
/// institutional approval before participant collection can be enabled.
abstract final class BrowserWorkspacePreferences {
  static Future<int> loadSelectedTab() =>
      implementation.loadSelectedTab();

  static Future<void> saveSelectedTab(int index) =>
      implementation.saveSelectedTab(index);
}
