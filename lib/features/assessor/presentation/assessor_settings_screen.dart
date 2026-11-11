import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/audio/kannada_instruction_audio_service.dart';
import '../../../core/config/assessment_release_gate.dart';
import '../../../core/config/study_protocol.dart';
import '../../assessment/data/bundled_item_catalog.dart';

class AssessorSettingsScreen extends StatefulWidget {
  const AssessorSettingsScreen({super.key});

  @override
  State<AssessorSettingsScreen> createState() => _AssessorSettingsScreenState();
}

class _AssessorSettingsScreenState extends State<AssessorSettingsScreen> {
  late final Future<BundledItemCatalog> _catalogFuture;
  late final KannadaInstructionAudioService _audioService;
  late final Future<bool> _audioReadyFuture;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _catalogFuture = BundledItemCatalog.load();
    _audioService = KannadaInstructionAudioService();
    _audioReadyFuture = _audioService.isReady;
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      body: SafeArea(
        child: FutureBuilder<BundledItemCatalog>(
          future: _catalogFuture,
          builder: (context, catalogSnapshot) {
            final catalog = catalogSnapshot.data;
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 30,
                    compact ? 20 : 30,
                    compact ? 16 : 30,
                    36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'SETTINGS & CONFIGURATION',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.teal,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Application settings',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.deepInk,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Inspect the bundled assessment content, Kannada '
                            'recording package, local data protection and '
                            'field-release requirements.',
                            style: TextStyle(
                              color: AppTheme.muted,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (catalogSnapshot.connectionState ==
                              ConnectionState.waiting)
                            const LinearProgressIndicator(minHeight: 3),
                          if (catalogSnapshot.hasError)
                            _statusCard(
                              title: 'Item catalogue validation failed',
                              message: catalogSnapshot.error.toString(),
                              color: AppTheme.coral,
                            ),
                          if (catalog != null) ...<Widget>[
                            _itemBankCard(catalog),
                            const SizedBox(height: 14),
                            _sourceWordBrowser(catalog),
                            const SizedBox(height: 14),
                            _nonWordProportions(catalog),
                            const SizedBox(height: 14),
                            _nonWordCandidateBrowser(catalog),
                          ],
                          const SizedBox(height: 14),
                          FutureBuilder<bool>(
                            future: _audioReadyFuture,
                            builder: (context, audioSnapshot) {
                              final ready = audioSnapshot.data == true;
                              return _audioCard(
                                ready: ready,
                                loading: audioSnapshot.connectionState ==
                                    ConnectionState.waiting,
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _dataProtectionCard(),
                          const SizedBox(height: 14),
                          _protocolCard(),
                          const SizedBox(height: 14),
                          _releaseBlockersCard(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _itemBankCard(BundledItemCatalog catalog) {
    return _sectionCard(
      icon: Icons.library_books_outlined,
      title: 'Supplied Kannada item bank',
      subtitle: 'Original source-word file bundled into the application',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _statusLine(
            label: 'Real Kannada words',
            value: catalog.realWords.length.toString() + ' / 270 loaded',
            good: catalog.hasCompleteRealWordPool,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Unique word entries',
            value: catalog.realWords.map((item) => item.text).toSet().length.toString(),
            good: catalog.hasCompleteRealWordPool,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Non-word candidates',
            value: catalog.nonWordCandidateCount.toString() + ' / 270',
            good: catalog.nonWordCandidateCount == 270,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Native review approval',
            value: catalog.approvedNonWordCount.toString() + ' / 270 approved',
            good: catalog.approvedNonWordCount == 270,
          ),
          const SizedBox(height: 12),
          const _Notice(
            text: 'The real-word list is included as supplied. Non-word '
                'candidates remain unavailable to the assessment engine until '
                'written native Kannada review approval is recorded.',
          ),
          const SizedBox(height: 14),
          Text(
            'Word metadata distribution',
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _distributionRows(
            'Part of speech',
            catalog.distributionBy((item) => item.partOfSpeech),
          ),
          const SizedBox(height: 10),
          _distributionRows(
            'Age band',
            catalog.distributionBy((item) => item.ageBand),
          ),
          const SizedBox(height: 10),
          _distributionRows(
            'Akshara type',
            catalog.distributionBy((item) => item.aksharaType),
          ),
        ],
      ),
    );
  }

  Widget _sourceWordBrowser(BundledItemCatalog catalog) {
    final words = catalog.realWords.where((item) {
      if (_search.isEmpty) return true;
      return item.text.toLowerCase().contains(_search) ||
          item.id.toLowerCase().contains(_search) ||
          item.transcription.toLowerCase().contains(_search) ||
          item.meaning.toLowerCase().contains(_search);
    }).toList(growable: false);

    return _sectionCard(
      icon: Icons.search_rounded,
      title: 'Review supplied real words',
      subtitle: catalog.realWords.length.toString() +
          ' source entries · W001–W270 identifiers assigned in source order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search Kannada word, ID, transcription or meaning',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            words.length.toString() + ' entries',
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: words.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.line),
              itemBuilder: (context, index) {
                final item = words[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    item.text,
                    style: const TextStyle(
                      color: AppTheme.deepInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    item.id + '  ·  ' + item.transcription + '  ·  ' +
                        item.meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    item.partOfSpeech,
                    style: const TextStyle(
                      color: AppTheme.tealDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _nonWordProportions(BundledItemCatalog catalog) {
    const methodLabels = <String, String>{
      'A_vowel': 'A · Vowel replacement',
      'B_consonant': 'B · Consonant replacement',
      'C_suffix_prefix': 'C · Suffix + prefix blend',
      'D_prefix_suffix': 'D · Prefix + suffix blend',
    };
    return _sectionCard(
      icon: Icons.rule_folder_outlined,
      title: 'Non-word construction proportions',
      subtitle: 'The supplied candidate workbook: 270 rows in four methods',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final entry in methodLabels.entries) ...<Widget>[
            _statusLine(
              label: entry.value,
              value: catalog.nonWordMethodCounts[entry.key].toString(),
              good: true,
            ),
            const SizedBox(height: 10),
          ],
          const _Notice(
            text: 'All 270 candidates are currently marked Pending in the '
                'supplied workbook. This summary is for audit and review only; '
                'the candidates are not loaded as usable stimuli.',
          ),
        ],
      ),
    );
  }


  Widget _nonWordCandidateBrowser(BundledItemCatalog catalog) {
    final candidates = catalog.suppliedNonWordCandidates.where((item) {
      if (_search.isEmpty) return true;
      return item.text.toLowerCase().contains(_search) ||
          item.id.toLowerCase().contains(_search) ||
          item.sourceWord1.toLowerCase().contains(_search) ||
          (item.sourceWord2?.toLowerCase().contains(_search) ?? false) ||
          item.method.toLowerCase().contains(_search);
    }).toList(growable: false);

    return _sectionCard(
      icon: Icons.fact_check_outlined,
      title: 'Supplied non-word candidates',
      subtitle: '193 supplied rows · all pending linguistic review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Notice(
            text: 'These are review candidates, not approved stimuli. '
                'They are visible for assessor/reviewer inspection only and '
                'cannot enter a participant session.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search candidate, ID, source word or method',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            candidates.length.toString() + ' of ' +
                catalog.suppliedNonWordCount.toString() + ' supplied candidates',
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.line),
              itemBuilder: (context, index) {
                final item = candidates[index];
                final sources = item.sourceWord2 == null
                    ? item.sourceWord1 + ' (' + item.sourceId1 + ')'
                    : item.sourceWord1 + ' (' + item.sourceId1 + ') · ' +
                        item.sourceWord2! + ' (' + item.sourceId2! + ')';
                return ListTile(
                  dense: true,
                  title: Text(
                    item.text,
                    style: const TextStyle(
                      color: AppTheme.deepInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    item.id + ' · ' + item.method + '\\n' + sources +
                        ' · ' + item.transformation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: AppTheme.coral,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioCard({required bool ready, required bool loading}) {
    return _sectionCard(
      icon: Icons.volume_up_outlined,
      title: 'Kannada instruction recordings',
      subtitle: 'Offline bundled audio · no device TTS fallback',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _statusLine(
            label: 'Approved audio package',
            value: loading
                ? 'Checking manifest'
                : ready
                    ? 'Installed'
                    : 'Not ready',
            good: ready,
          ),
          const SizedBox(height: 10),
          const _Notice(
            text: 'A source recording was supplied, but it has not yet been '
                'transcribed, segmented into the required instruction clips, '
                'and tied to a written PHFI/CDLR approval reference. The app '
                'will not synthesize speech or play an unapproved source file '
                'during participant sessions.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Required clips: assessor welcome, child instructions, practice '
            'instructions, completion instruction and reward instruction. '
            'Scored stimuli remain silent unless the PI approves otherwise.',
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataProtectionCard() {
    return _sectionCard(
      icon: Icons.security_outlined,
      title: 'Data protection and storage',
      subtitle: 'Android private storage · encrypted SQLite',
      child: Column(
        children: <Widget>[
          _statusLine(
            label: 'SQLCipher implementation',
            value: 'Code and host tests present',
            good: true,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Secure key storage',
            value: 'Integration present; tablet test pending',
            good: false,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Participant capture in Vercel',
            value: 'Disabled',
            good: true,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Export and recovery workflow',
            value: 'Implementation and acceptance pending',
            good: false,
          ),
          const SizedBox(height: 10),
          const Text(
            'The field build must keep participant information on the tablet. '
            'No analytics, crash upload, cloud sync or remote research API is '
            'configured in this application.',
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _protocolCard() {
    return _sectionCard(
      icon: Icons.policy_outlined,
      title: 'Protocol baseline',
      subtitle: StudyProtocol.requirementsVersion +
          ' · not approved for field use',
      child: Column(
        children: <Widget>[
          const _Notice(
            text: 'These values are transcribed requirements only. The study ' 
                'team has not approved the final session count, item allocation, ' 
                'stimulus timing or reward policy. They must not be used to ' 
                'administer a participant assessment.',
          ),
          const SizedBox(height: 14),
          _statusLine(
            label: 'Sessions',
            value: StudyProtocol.sessionCount.toString(),
            good: false,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Presentations per session',
            value: StudyProtocol.presentationsPerSession.toString(),
            good: false,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Practice / test',
            value: StudyProtocol.practicePresentationsPerSession.toString() +
                ' practice + ' +
                StudyProtocol.testPresentationsPerSession.toString() +
                ' test',
            good: false,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Stimulus duration',
            value: StudyProtocol.stimulusDisplayDuration.inSeconds.toString() +
                ' seconds',
            good: false,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Reward interval',
            value: 'Every ' +
                StudyProtocol.rewardIntervalAnswers.toString() +
                ' answers',
            good: false,
          ),
          const SizedBox(height: 10),
          const _Notice(
            text: 'The requirements document says the visit schedule is to be '
                'finalised with the study team. Session scheduling, allocation '
                'and other protocol rules must be approved before administration.',
          ),
        ],
      ),
    );
  }

  Widget _releaseBlockersCard() {
    final blockers = AssessmentReleaseGate.current.blockers;
    return _sectionCard(
      icon: Icons.fact_check_outlined,
      title: 'Production release requirements',
      subtitle: blockers.length.toString() + ' items remain open',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final blocker in blockers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: AppTheme.coral,
                    size: 16,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      blocker,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
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
                          color: AppTheme.deepInk,
                          fontWeight: FontWeight.w900,
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

  Widget _statusLine({
    required String label,
    required String value,
    required bool good,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          good ? Icons.check_circle_outline : Icons.pending_outlined,
          color: good ? AppTheme.teal : AppTheme.coral,
          size: 17,
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _distributionRows(String title, Map<String, int> distribution) {
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.deepInk,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    color: AppTheme.deepInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statusCard({
    required String title,
    required String message,
    required Color color,
  }) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
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
