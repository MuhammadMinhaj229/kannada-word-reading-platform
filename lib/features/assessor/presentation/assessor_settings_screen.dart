import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/demo/demo_record_store.dart';
import '../../assessment/data/demo_export_service.dart';
import '../../assessment/data/item_bank_import_metadata_store.dart';
import '../../assessment/data/item_bank_import_service.dart';
import '../../assessment/data/item_bank_template_service.dart';

import '../../../app/app_theme.dart';
import '../../../core/audio/kannada_speech_service.dart';
import '../../../core/config/assessment_release_gate.dart';
import '../../../core/config/study_protocol.dart';

class AssessorSettingsScreen extends StatefulWidget {
  const AssessorSettingsScreen({
    required this.demoMode,
    super.key,
  });

  final bool demoMode;

  @override
  State<AssessorSettingsScreen> createState() => _AssessorSettingsScreenState();
}

class _AssessorSettingsScreenState extends State<AssessorSettingsScreen> {
  final KannadaSpeechService _speech = KannadaSpeechService.instance;
  bool _voiceAvailable = false;
  bool _checkingVoice = true;
  bool _testingVoice = false;
  bool _autoVoice = KannadaSpeechService.instance.enabled;
  String? _audioMessage;

  final ItemBankImportService _bankImporter = ItemBankImportService();
  final ItemBankImportMetadataStore _bankMetadataStore =
      ItemBankImportMetadataStore();
  final ItemBankTemplateService _templateService = ItemBankTemplateService();
  final DemoExportService _demoExportService = DemoExportService();

  bool _bankBusy = false;
  bool _exportBusy = false;
  List<String> _bankErrors = <String>[];
  ItemBankImportMetadata? _bankMetadata;
  String? _bankFeedback;
  String? _exportFeedback;
  int _demoRecordCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshVoice();
    _loadLocalSettings();
  }

  Future<void> _refreshLocalSettings() async {
    await _loadLocalSettings();
    if (!mounted) return;
    setState(() {
      _exportFeedback = 'Local synthetic demo records refreshed.';
    });
  }

  Future<void> _loadLocalSettings() async {
    try {
      final metadata = await _bankMetadataStore.load();
      final records = await DemoRecordStore.instance.readAll();
      if (!mounted) return;
      setState(() {
        _bankMetadata = metadata;
        _demoRecordCount = records.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bankFeedback = 'Local review metadata could not be read.';
      });
    }
  }

  Future<void> _downloadBankTemplate() async {
    setState(() {
      _bankBusy = true;
      _bankFeedback = null;
      _bankErrors = <String>[];
    });
    try {
      await _templateService.downloadTemplate();
      if (!mounted) return;
      setState(() => _bankFeedback = 'The blank 540-row authoring template was generated.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _bankFeedback = 'Could not create the item-bank template.');
    } finally {
      if (mounted) setState(() => _bankBusy = false);
    }
  }

  Future<void> _pickAndValidateBank() async {
    if (_bankBusy) return;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>['xlsx'],
    );
    if (file == null) return;

    setState(() {
      _bankBusy = true;
      _bankFeedback = 'Reading and validating workbook…';
      _bankErrors = <String>[];
    });

    try {
      final bytes = await file.readAsBytes();
      final result = await _bankImporter.parse(
        fileName: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      if (!result.valid) {
        setState(() {
          _bankFeedback = 'Rejected — structural validation found issues.';
          _bankErrors = result.errors.take(12).toList(growable: false);
        });
        return;
      }

      final metadata = ItemBankImportMetadata(
        fileName: result.fileName,
        version: result.version,
        sha256: result.sha256,
        importedAt: DateTime.now().toUtc().toIso8601String(),
        itemCount: result.items.length,
        wordCount: result.wordCount,
        nonWordCount: result.nonWordCount,
      );
      await _bankMetadataStore.save(metadata);
      if (!mounted) return;
      setState(() {
        _bankMetadata = metadata;
        _bankFeedback =
            'Structural checks passed. Item content remains outside this demo store and is not used by the game.';
        _bankErrors = <String>[];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bankFeedback = 'Could not import this workbook. Check that it is a valid .xlsx file.';
      });
    } finally {
      if (mounted) setState(() => _bankBusy = false);
    }
  }

  Future<void> _exportDemo(bool asExcel) async {
    if (_exportBusy) return;
    setState(() {
      _exportBusy = true;
      _exportFeedback = null;
    });
    try {
      final result = asExcel
          ? await _demoExportService.exportXlsx()
          : await _demoExportService.exportCsv();
      if (!mounted) return;
      setState(() {
        _exportFeedback =
            'Saved ${result.fileName} · ${result.recordCount} synthetic demo responses.';
        _demoRecordCount = result.recordCount;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _exportFeedback = error is StateError
            ? error.message.toString()
            : 'The synthetic demo export failed.';
      });
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  Future<void> _clearDemoRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear synthetic demo records?'),
        content: const Text(
          'This removes only the locally stored synthetic game responses on this device/browser. It does not remove participant data because participant capture is disabled.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear demo records'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DemoRecordStore.instance.clear();
    if (!mounted) return;
    setState(() {
      _demoRecordCount = 0;
      _exportFeedback = 'Synthetic demo records cleared from this device/browser.';
    });
  }

  Future<void> _refreshVoice() async {
    final available = await _speech.isKannadaVoiceAvailable(refresh: true);
    if (!mounted) return;
    setState(() {
      _voiceAvailable = available;
      _checkingVoice = false;
    });
  }

  Future<void> _testVoice() async {
    if (!_autoVoice || !_voiceAvailable || _testingVoice) return;
    setState(() {
      _testingVoice = true;
      _audioMessage = null;
    });

    try {
      await _speech.speakPreview('ನಮಸ್ಕಾರ! ಕನ್ನಡ ಪದ ಓದುವ ಆಟಕ್ಕೆ ಸ್ವಾಗತ.');
      if (!mounted) return;
      setState(() => _audioMessage = 'Kannada speech preview completed.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audioMessage = error is StateError
            ? error.message.toString()
            : 'The device could not play the Kannada speech preview.';
      });
    } finally {
      if (mounted) setState(() => _testingVoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockers = AssessmentReleaseGate.current.blockers;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
              children: <Widget>[
                Text(
                  'SETTINGS & CONFIGURATION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Assessor settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.deepInk,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Prepare the review experience and inspect the release status. '
                  'Participant administration stays locked until the study approvals and '
                  'field validations are complete.',
                  style: TextStyle(color: AppTheme.muted, height: 1.55),
                ),
                const SizedBox(height: 22),
                _sectionCard(
                  context,
                  icon: Icons.volume_up_outlined,
                  title: 'Kannada voice preview',
                  subtitle: 'Device speech is for demo feedback only.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Automatic Kannada voice preview',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'May speak the welcome and demo reward messages. '
                          'Scored stimuli remain silent.',
                        ),
                        value: _autoVoice,
                        onChanged: widget.demoMode
                            ? (enabled) {
                                setState(() {
                                  _autoVoice = enabled;
                                  _speech.enabled = enabled;
                                  _audioMessage = null;
                                });
                              }
                            : null,
                      ),
                      const Divider(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  _checkingVoice
                                      ? Icons.hourglass_top_rounded
                                      : _voiceAvailable
                                          ? Icons.check_circle_outline
                                          : Icons.warning_amber_rounded,
                                  color: _checkingVoice
                                      ? AppTheme.muted
                                      : _voiceAvailable
                                          ? AppTheme.teal
                                          : AppTheme.coral,
                                  size: 19,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    _checkingVoice
                                        ? 'Checking device Kannada voice…'
                                        : _voiceAvailable
                                            ? 'Kannada voice available'
                                            : 'Kannada voice not available',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _checkingVoice ? null : _refreshVoice,
                            icon: const Icon(Icons.refresh_rounded, size: 17),
                            label: const Text('Check'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: !_autoVoice ||
                                  !_voiceAvailable ||
                                  _testingVoice
                              ? null
                              : _testVoice,
                          icon: _testingVoice
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            _testingVoice ? 'Speaking…' : 'Test Kannada voice',
                          ),
                        ),
                      ),
                      if (_audioMessage != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _audioMessage!,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _warning(
                        'This uses the voice supplied by the device/browser. '
                        'It does not guarantee a female voice or consistent pronunciation. '
                        'The final field app must use the locally bundled, PHFI/CDLR-approved '
                        'Kannada recordings. This preview voice must not replace those assets.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  context,
                  icon: Icons.assignment_ind_outlined,
                  title: 'Session setup',
                  subtitle: 'Child, assessor, visit and session history',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _StatusLine(
                        label: 'Participant workflow',
                        value: 'Release locked',
                        good: false,
                      ),
                      const SizedBox(height: 8),
                      const _StatusLine(
                        label: 'Session records',
                        value: 'Database API not connected to screens',
                        good: false,
                      ),
                      const SizedBox(height: 10),
                      _warning(
                        'Child identification, duplicate-session checks, supervisor '
                        'authentication and interruption recovery remain disabled. '
                        'No participant details should be entered in this build.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  context,
                  icon: Icons.library_books_outlined,
                  title: 'Item bank',
                  subtitle: 'Approved Kannada real words and non-words',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _StatusLine(
                        label: 'Required item pool',
                        value: '270 real + 270 non-words',
                        good: true,
                      ),
                      const SizedBox(height: 7),
                      _StatusLine(
                        label: 'Last validated workbook',
                        value: _bankMetadata == null
                            ? 'None imported'
                            : '${_bankMetadata!.itemCount} rows · SHA-256 verified',
                        good: _bankMetadata != null,
                      ),
                      if (_bankMetadata != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _bankMetadata!.fileName + '\n' +
                              'Imported: ' + _bankMetadata!.importedAt + '\n' +
                              'Hash: ' + _bankMetadata!.sha256,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: _bankBusy ? null : _downloadBankTemplate,
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Download Excel template'),
                          ),
                          FilledButton.icon(
                            onPressed: _bankBusy ? null : _pickAndValidateBank,
                            icon: _bankBusy
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_file_rounded),
                            label: Text(_bankBusy ? 'Validating…' : 'Import .xlsx'),
                          ),
                        ],
                      ),
                      if (_bankFeedback != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          _bankFeedback!,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (_bankErrors.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        for (final error in _bankErrors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ' + error,
                              style: const TextStyle(
                                color: AppTheme.coral,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 10),
                      _warning(
                        'Structural checks cover 540 rows, 270 words, 270 non-words, 6 balanced blocks, unique IDs/text and row ordering. They cannot certify Kannada linguistic validity or prove the reviewer identity. The workbook is not connected to the synthetic game or participant workflow.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  context,
                  icon: Icons.file_download_outlined,
                  title: 'Reports and export',
                  subtitle: 'Local trial and session summaries',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatusLine(
                              label: 'Synthetic responses stored',
                              value: _demoRecordCount.toString(),
                              good: _demoRecordCount > 0,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _exportBusy ? null : _refreshLocalSettings,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: _exportBusy ? null : () => _exportDemo(false),
                            icon: const Icon(Icons.table_rows_outlined),
                            label: const Text('Download CSV'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _exportBusy ? null : () => _exportDemo(true),
                            icon: const Icon(Icons.grid_on_outlined),
                            label: const Text('Download Excel'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _demoRecordCount == 0 || _exportBusy
                                ? null
                                : _clearDemoRecords,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Clear demo data'),
                          ),
                        ],
                      ),
                      if (_exportFeedback != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          _exportFeedback!,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _warning(
                        'CSV exports include a UTF-8 BOM and formula-injection-safe cells. Excel exports include trial details and an Export Info sheet. These files contain synthetic demo responses only. Participant exports, supervisor PIN, audit trail, backup/restore and retention remain disabled.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  context,
                  icon: Icons.policy_outlined,
                  title: 'Protocol and release status',
                  subtitle: 'Requirements baseline: ' + StudyProtocol.requirementsVersion,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _StatusLine(
                        label: 'Sessions in requirements draft',
                        value: StudyProtocol.sessionCount.toString(),
                        good: true,
                      ),
                      const SizedBox(height: 7),
                      _StatusLine(
                        label: 'Items per session',
                        value: StudyProtocol.presentationsPerSession.toString() +
                            ' (' +
                            StudyProtocol.practicePresentationsPerSession.toString() +
                            ' practice + ' +
                            StudyProtocol.testPresentationsPerSession.toString() +
                            ' test)',
                        good: true,
                      ),
                      const SizedBox(height: 7),
                      const _StatusLine(
                        label: 'Signed field-release manifest',
                        value: 'Missing',
                        good: false,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        blockers.length.toString() + ' release blockers remain.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.coral,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'The requirements document itself says the session schedule '
                        'must be finalised with the study team. These draft numbers must '
                        'not be treated as the approved study allocation.',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  context,
                  icon: Icons.offline_bolt_outlined,
                  title: 'Offline and updates',
                  subtitle: 'Shared Flutter screens on Web and Android',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _StatusLine(
                        label: 'Application resources',
                        value: 'Bundled with each build',
                        good: true,
                      ),
                      SizedBox(height: 7),
                      _StatusLine(
                        label: 'Android data store',
                        value: 'SQLCipher foundation; UI wiring pending',
                        good: false,
                      ),
                      SizedBox(height: 7),
                      _StatusLine(
                        label: 'Web data store',
                        value: 'No participant storage enabled',
                        good: false,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'An offline shell is not the same as validated offline data '
                        'capture. Web demo caching, browser persistence, native encrypted '
                        'storage and update-during-session behavior must all be tested '
                        'separately before field use.',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.demoMode
                      ? 'SYNTHETIC DEMO BUILD · NO PARTICIPANT DATA'
                      : 'FIELD RELEASE LOCKED · DO NOT USE WITH PARTICIPANTS',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.coral,
                    letterSpacing: 1.1,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppTheme.tealDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _warning(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E7),
        border: Border.all(color: const Color(0xFFF2E2C3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF765C2B),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    required this.good,
  });

  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          good ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 17,
          color: good ? AppTheme.teal : AppTheme.coral,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
