import 'dart:html' as html;

const _storageKey = 'padalab.web.workspace.selected-tab.v1';
const _tabCount = 3;

/// Persists only the selected non-sensitive navigation tab in localStorage.
/// No participant identifiers, trial data or research records are accepted.
Future<int> loadSelectedTab() async {
  try {
    final raw = html.window.localStorage[_storageKey];
    final value = int.tryParse(raw ?? '');
    if (value == null || value < 0 || value >= _tabCount) return 0;
    return value;
  } catch (_) {
    // Private browsing, storage denial or browser policy must not prevent the
    // Web application from opening. The preference simply falls back to tab 0.
    return 0;
  }
}

Future<void> saveSelectedTab(int index) async {
  if (index < 0 || index >= _tabCount) return;
  try {
    html.window.localStorage[_storageKey] = index.toString();
  } catch (_) {
    // Storage is best-effort for this non-sensitive preference. Core UI stays
    // usable if localStorage is disabled or full.
  }
}
