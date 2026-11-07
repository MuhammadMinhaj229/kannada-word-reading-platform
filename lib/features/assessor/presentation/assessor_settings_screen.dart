import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshVoice();
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
                        label: 'Planned item pool',
                        value: '270 real + 270 non-words',
                        good: true,
                      ),
                      const SizedBox(height: 7),
                      const _StatusLine(
                        label: 'Approved non-words',
                        value: '0 / 270',
                        good: false,
                      ),
                      const SizedBox(height: 10),
                      _warning(
                        'The 270 non-word candidates still require native Kannada review '
                        'and Suganya’s written approval. The final approved workbook and '
                        'checksum are not installed. The demo never uses this item bank.',
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
                      const _StatusLine(
                        label: 'Export workflow',
                        value: 'Not implemented',
                        good: false,
                      ),
                      const SizedBox(height: 8),
                      const _StatusLine(
                        label: 'Data location',
                        value: 'No participant data is collected',
                        good: true,
                      ),
                      const SizedBox(height: 10),
                      _warning(
                        'PIN-protected CSV export, UTF-8 BOM, include-name option, '
                        'audit history, backup/restore and retention controls must be '
                        'completed and approved before any real assessment.',
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
