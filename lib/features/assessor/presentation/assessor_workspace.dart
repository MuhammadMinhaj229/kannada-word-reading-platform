import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/storage/browser_workspace_preferences.dart';
import 'assessor_home_screen.dart';
import 'assessor_settings_screen.dart';
import 'child_task_simulation_screen.dart';

/// Shared responsive navigation for Android tablets and browser review.
class AssessorWorkspace extends StatefulWidget {
  const AssessorWorkspace({super.key});

  @override
  State<AssessorWorkspace> createState() => _AssessorWorkspaceState();
}

class _AssessorWorkspaceState extends State<AssessorWorkspace> {
  int _selectedIndex = 0;
  bool _userSelectedTab = false;

  @override
  void initState() {
    super.initState();
    _restoreSelectedTab();
  }

  Future<void> _restoreSelectedTab() async {
    final savedIndex = await BrowserWorkspacePreferences.loadSelectedTab();
    if (!mounted || _userSelectedTab || savedIndex == _selectedIndex) return;
    setState(() => _selectedIndex = savedIndex);
  }

  void _selectDestination(int index) {
    if (index < 0 || index >= _destinations.length) return;
    _userSelectedTab = true;
    setState(() => _selectedIndex = index);
    unawaited(BrowserWorkspacePreferences.saveSelectedTab(index));
  }

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment_rounded),
      label: 'Assessment',
    ),
    NavigationDestination(
      icon: Icon(Icons.play_circle_outline_rounded),
      selectedIcon: Icon(Icons.play_circle_fill_rounded),
      label: 'Task preview',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_outlined),
      selectedIcon: Icon(Icons.tune_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final pages = IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            const AssessorHomeScreen(),
            ChildTaskSimulationScreen(isActive: _selectedIndex == 1),
            const AssessorSettingsScreen(),
          ],
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme: const IconThemeData(
                    color: AppTheme.tealDark,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.tealDark,
                    fontWeight: FontWeight.w800,
                  ),
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment_rounded),
                      label: Text('Assessment'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.play_circle_outline_rounded),
                      selectedIcon: Icon(Icons.play_circle_fill_rounded),
                      label: Text('Task preview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tune_outlined),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: pages),
              ],
            ),
          );
        }

        return Scaffold(
          body: pages,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectDestination,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
