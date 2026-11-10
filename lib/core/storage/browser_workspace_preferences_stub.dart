/// Non-Web fallback. Android preferences and participant records are managed
/// by their own platform-specific services, never through browser storage.
Future<int> loadSelectedTab() async => 0;

Future<void> saveSelectedTab(int index) async {}
