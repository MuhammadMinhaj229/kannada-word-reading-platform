import 'package:flutter/material.dart';

import '../features/assessment/data/item_bank_draft_store_contract.dart';
import '../features/assessor/presentation/assessor_workspace.dart';
import 'app_theme.dart';

class PadalabApp extends StatelessWidget {
  const PadalabApp({super.key, this.contentDraftStore});

  /// Optional persistence adapter for deterministic tests and controlled
  /// embedding. Production uses the platform adapter by default.
  final ItemBankDraftStore? contentDraftStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ಪದLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AssessorWorkspace(draftStore: contentDraftStore),
    );
  }
}
