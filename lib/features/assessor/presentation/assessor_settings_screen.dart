import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/audio/kannada_instruction_audio_service.dart';
import '../../../core/config/assessment_release_gate.dart';
import '../../../core/config/study_protocol.dart';
import '../../assessment/data/bundled_item_catalog.dart';
import '../../assessment/data/item_bank_draft_store_contract.dart';
import '../../assessment/domain/models/allocation_proposal.dart';
import 'item_bank_draft_manager.dart';

class AssessorSettingsScreen extends StatefulWidget {
  const AssessorSettingsScreen({super.key, this.draftStore});

  final ItemBankDraftStore? draftStore;

  @override
  State<AssessorSettingsScreen> createState() => _AssessorSettingsScreenState();
}

class _AssessorSettingsScreenState extends State<AssessorSettingsScreen> {
  late final Future<BundledItemCatalog> _catalogFuture;
  late final Future<AllocationProposal> _allocationProposalFuture;
  late final KannadaInstructionAudioService _audioService;
  late final Future<KannadaAudioPackageAudit> _audioAuditFuture;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _catalogFuture = BundledItemCatalog.load();
    _allocationProposalFuture = AllocationProposal.load();
    _audioService = KannadaInstructionAudioService();
    _audioAuditFuture = _catalogFuture.then(
      (catalog) => _audioService.auditPackage(
        wordItemIds: catalog.realWords.map((item) => item.id),
      ),
    );
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
                            ItemBankDraftManager(
                              catalog: catalog,
                              store: widget.draftStore,
                            ),
                            const SizedBox(height: 14),
                            _sourceWordBrowser(catalog),
                            const SizedBox(height: 14),
                            _nonWordProportions(catalog),
                            const SizedBox(height: 14),
                            _nonWordCandidateBrowser(catalog),
                            const SizedBox(height: 14),
                            FutureBuilder<AllocationProposal>(
                              future: _allocationProposalFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return _statusCard(
                                    title: 'Allocation proposal invalid',
                                    message: snapshot.error.toString(),
                                    color: AppTheme.coral,
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const LinearProgressIndicator(minHeight: 2);
                                }
                                return _allocationProposalCard(snapshot.data!);
                              },
                            ),
                          ],
                          const SizedBox(height: 14),
                          FutureBuilder<KannadaAudioPackageAudit>(
                            future: _audioAuditFuture,
                            builder: (context, audioSnapshot) {
                              return _audioCard(
                                report: audioSnapshot.data,
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
            label: 'Original workbook candidate summary',
            value: catalog.nonWordCandidateCount.toString() + ' candidates',
            good: catalog.nonWordCandidateCount == 270,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Candidate rows bundled for review',
            value: catalog.suppliedNonWordCount.toString() + ' / ' +
                catalog.nonWordCandidateCount.toString() + ' summary rows',
            good: catalog.suppliedNonWordCount ==
                catalog.nonWordCandidateCount,
          ),
          const SizedBox(height: 9),
          _statusLine(
            label: 'Difference between summary and bundled CSV',
            value: catalog.nonWordCandidateCountDifference.toString() +
                ' rows not represented in the CSV',
            good: catalog.nonWordCandidateCountDifference == 0,
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
      title: 'Original supplied real-word source · read-only',
      subtitle: catalog.realWords.length.toString() +
          ' bundled source entries · edit working copies in Draft workspace',
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
                return Material(
                  color: Colors.white,
                  child: ListTile(
                  dense: true,
                  onTap: () => _playWord(item.id),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        item.partOfSpeech,
                        style: const TextStyle(
                          color: AppTheme.tealDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      _wordAudioButton(item.id),
                    ],
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


  Widget _wordAudioButton(String itemId) {
    return FutureBuilder<bool>(
      future: _audioService.hasWordRecording(itemId),
      builder: (context, snapshot) {
        final available = snapshot.data == true;
        return IconButton(
          tooltip: available
              ? 'Play approved Kannada recording'
              : 'Approved recording not installed',
          icon: Icon(
            available ? Icons.volume_up_rounded : Icons.volume_off_outlined,
            color: available ? AppTheme.tealDark : AppTheme.muted,
            size: 19,
          ),
          onPressed: available ? () => _playWord(itemId) : null,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }

  Future<void> _playWord(String itemId) async {
    try {
      await _audioService.playWord(itemId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Approved word recordings are not installed yet. '
            'The supplied source recording still needs review and segmentation.',
          ),
        ),
      );
    }
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
      subtitle: 'Original workbook summary (270) compared with bundled review CSV (193)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final entry in methodLabels.entries) ...<Widget>[
            _statusLine(
              label: entry.value,
              value: (catalog.nonWordMethodCounts[entry.key] ?? 0)
                      .toString() +
                  ' summary · ' +
                  (catalog.suppliedNonWordMethodCounts[entry.key] ?? 0)
                      .toString() +
                  ' in CSV',
              good: (catalog.nonWordMethodCounts[entry.key] ?? 0) ==
                  (catalog.suppliedNonWordMethodCounts[entry.key] ?? 0),
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
      title: 'Original supplied non-word source · read-only',
      subtitle: '193 bundled source rows · all pending native Kannada review · edit working copies in Draft workspace',
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
                return Material(
                  color: Colors.white,
                  child: ListTile(
                  dense: true,
                  onTap: () => _playWord(item.id),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'PENDING',
                        style: TextStyle(
                          color: AppTheme.coral,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      _wordAudioButton(item.id),
                    ],
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


  Widget _allocationProposalCard(AllocationProposal proposal) {
    return _sectionCard(
      icon: Icons.calendar_view_week_outlined,
      title: 'Six-session allocation proposal',
      subtitle: proposal.version + ' · engineering draft only',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _summaryMetric(
                  value: proposal.realWordsPerSession.toString(),
                  label: 'Real words / session',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryMetric(
                  value: proposal.nonWordsPerSession.toString(),
                  label: 'Non-words / session',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryMetric(
                  value: proposal.scoredItemsPerSession.toString(),
                  label: 'Scored / session',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final session in proposal.sessionDistribution) ...<Widget>[
            _statusLine(
              label: 'Session ' + session.session.toString(),
              value: session.realWords.toString() + ' real + ' +
                  session.nonWords.toString() + ' non-word = ' +
                  session.scoredItems.toString(),
              good: true,
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 6),
          _statusLine(
            label: 'Total scored presentations',
            value: proposal.totalScoredItems.toString(),
            good: true,
          ),
          const SizedBox(height: 8),
          _statusLine(
            label: 'Unallocated reserve candidate',
            value: proposal.reserveNonWordId,
            good: false,
          ),
          const SizedBox(height: 12),
          _Notice(
            text: 'Practice items are not included in the 77 scored items. ' +
                proposal.practicePolicy + ' This proposal does not enable participant sessions.',
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.tealDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioCard({
    required KannadaAudioPackageAudit? report,
    required bool loading,
  }) {
    final instructionReady = report?.instructionReady == true;
    final wordReady = report?.wordAudioReady == true;
    final instructionPresent = report?.instructionAssetPresentCount ?? 0;
    final instructionMapped = report?.instructionMappedCount ?? 0;
    final instructionApproved = report?.instructionApprovedAssetCount ?? 0;
    final wordCount = report?.wordRequiredCount ?? 270;
    final wordReadyCount = report?.wordReadyCount ?? 0;
    final issues = <String>[
      ...?report?.instructionIssues.take(3),
      ...?report?.wordIssues.take(3),
    ];
    final moreIssues = (report?.instructionIssues.length ?? 0) +
        (report?.wordIssues.length ?? 0) -
        issues.length;
    final missingExamples = report?.missingWordIds.take(5).toList() ??
        const <String>[];

    return _sectionCard(
      icon: Icons.volume_up_outlined,
      title: 'Kannada instruction and word recordings',
      subtitle: 'Offline bundled audio · explicit batch and item approval · no TTS fallback',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _statusLine(
            label: 'Instruction clips',
            value: loading
                ? 'Auditing 5 required clips'
                : instructionApproved.toString() + ' / 5 approved and present · ' +
                    instructionMapped.toString() + ' mapped · ' +
                    instructionPresent.toString() + ' files found',
            good: instructionReady,
          ),
          const SizedBox(height: 10),
          _statusLine(
            label: 'Real-word recordings',
            value: loading
                ? 'Auditing ' + wordCount.toString() + ' items'
                : wordReadyCount.toString() + ' / ' + wordCount.toString() +
                    ' fully approved and present',
            good: wordReady,
          ),
          const SizedBox(height: 10),
          if (loading)
            const LinearProgressIndicator(minHeight: 2)
          else if (report == null || !report.manifestReadable)
            const _Notice(
              text: 'The audio manifest could not be validated. Playback remains disabled.',
            )
          else ...<Widget>[
            _Notice(
              text: instructionReady
                  ? 'All five required instruction clips have an approved reference and a non-empty bundled asset.'
                  : 'Instruction coverage is incomplete. Required keys: assessor_welcome, child_instructions, practice_instructions, completion_instruction and reward_instruction.',
            ),
            const SizedBox(height: 8),
            _Notice(
              text: wordReady
                  ? 'Every supplied real-word item has a batch approval, an item-level approval reference and a bundled recording.'
                  : 'Word recordings are not ready. Each item needs a mapped bundled file, word-audio batch approval and its own item-level review reference.',
            ),
            if (missingExamples.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Example missing word recordings: ' +
                    missingExamples.join(', ') +
                    (report.missingWordIds.length > missingExamples.length
                        ? ', …'
                        : ''),
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                ),
              ),
            ],
            if (issues.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                <String>[
                  'Audio audit findings:',
                  ...issues.map((issue) => '• ' + issue),
                  if (moreIssues > 0)
                    '…and ' + moreIssues.toString() + ' additional findings.',
                ].join('\n'),
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Text(
            'The supplied source recording has not been transcribed, segmented, linguistically reviewed or approved. This audit verifies manifest references and bundled file presence; it cannot judge pronunciation clarity or child comprehension. Scored stimuli remain silent unless the PI approves a protocol amendment.',
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
