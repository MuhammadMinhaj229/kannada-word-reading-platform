import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../features/assessor/presentation/assessor_home_screen.dart';

class PadalabApp extends StatelessWidget {
  const PadalabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ಪದLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AssessorHomeScreen(),
    );
  }
}
