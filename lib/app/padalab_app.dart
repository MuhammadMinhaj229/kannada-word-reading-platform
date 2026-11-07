import 'package:flutter/material.dart';

import '../features/assessor/presentation/assessor_workspace.dart';
import 'app_theme.dart';

class PadalabApp extends StatelessWidget {
  const PadalabApp({
    this.demoMode = false,
    super.key,
  });

  /// Must be true only for synthetic review/training builds.
  /// Release builds default to the participant-safe locked screen.
  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ಪದLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AssessorWorkspace(demoMode: demoMode),
    );
  }
}
