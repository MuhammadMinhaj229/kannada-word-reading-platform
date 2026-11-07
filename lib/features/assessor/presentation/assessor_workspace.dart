import 'package:flutter/material.dart';

import 'assessor_home_screen.dart';
import 'assessor_settings_screen.dart';

/// Two-tab application shell shared by the Flutter Web and Android targets.
class AssessorWorkspace extends StatefulWidget {
  const AssessorWorkspace({
    required this.demoMode,
    super.key,
  });

  final bool demoMode;

  @override
  State<AssessorWorkspace> createState() => _AssessorWorkspaceState();
}

class _AssessorWorkspaceState extends State<AssessorWorkspace> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          AssessorHomeScreen(demoMode: widget.demoMode),
          AssessorSettingsScreen(demoMode: widget.demoMode),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: 'Game',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
