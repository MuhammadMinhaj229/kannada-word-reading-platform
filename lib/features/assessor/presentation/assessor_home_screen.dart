import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/assessment_release_gate.dart';
import '../../../core/config/study_protocol.dart';
import '../../../core/update/play_update_service.dart';
import '../../../core/update/web_update_service.dart';
import '../../../core/update/apk_download_service.dart';
import '../../assessment/data/bundled_item_catalog.dart';

class AssessorHomeScreen extends StatefulWidget {
  const AssessorHomeScreen({super.key});

  @override
  State<AssessorHomeScreen> createState() => _AssessorHomeScreenState();
}

class _AssessorHomeScreenState extends State<AssessorHomeScreen> {
  late final Future<BundledItemCatalog> _catalogFuture;

  final _childIdController = TextEditingController();
  final _confirmChildIdController = TextEditingController();
  final _childNameController = TextEditingController();
  final _assessorIdController = TextEditingController();

  bool get _canCollectIdentifiers =>
      !kIsWeb && AssessmentReleaseGate.current.isOpen;

  @override
  void initState() {
    super.initState();
    _catalogFuture = BundledItemCatalog.load();
  }

  @override
  void dispose() {
    _childIdController.dispose();
    _confirmChildIdController.dispose();
    _childNameController.dispose();
    _assessorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 860;
            final horizontalPadding = compact ? 16.0 : 30.0;
            return FutureBuilder<BundledItemCatalog>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                final catalog = snapshot.data;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 18 : 28,
                    horizontalPadding,
                    32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _header(context),
                          const SizedBox(height: 26),
                          _intro(context),
                          const SizedBox(height: 22),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            const LinearProgressIndicator(minHeight: 3),
                          if (snapshot.hasError)
                            _errorCard(snapshot.error.toString()),
                          if (catalog != null) ...<Widget>[
                            _metrics(context, catalog),
                            const SizedBox(height: 20),
                          ],
                          if (compact)
                            _sessionEntryCard()
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 11,
                                  child: _sessionEntryCard(),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 9,
                                  child: _readinessCard(catalog),
                                ),
                              ],
                            ),
                          if (compact) ...<Widget>[
                            const SizedBox(height: 18),
                            _readinessCard(catalog),
                          ],
                          const SizedBox(height: 20),
                          _releaseNotice(),
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

  Widget _header(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 560;
    final identity = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ಪದLab',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.deepInk,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Text(
                'KANNADA WORD READING ASSESSMENT',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final status = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        const _StatusPill(
          icon: Icons.cloud_off_rounded,
          label: 'OFFLINE-FIRST',
          color: AppTheme.teal,
        ),
        _StatusPill(
          icon: kIsWeb ? Icons.visibility_outlined : Icons.lock_outline_rounded,
          label: kIsWeb ? 'BROWSER REVIEW · READ ONLY' : 'FIELD RELEASE GATED',
          color: AppTheme.coral,
        ),
        if (kIsWeb) ...<Widget>[
          const _ManualWebUpdateButton(),
          const _ApkDownloadButton(),
        ] else if (!kDebugMode &&
            defaultTargetPlatform == TargetPlatform.android &&
            AppConfig.playUpdatesEnabled)
          const _ManualUpdateButton(),
      ],
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          identity,
          const SizedBox(height: 12),
          status,
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: identity),
        const SizedBox(width: 16),
        status,
      ],
    );
  }

  Widget _intro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'FIELD ASSESSMENT WORKSPACE',
            style: TextStyle(
              color: AppTheme.tealDark,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Kannada word-reading\nassessment',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.deepInk,
                height: 1.07,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'An offline-first assessor application for recording structured '
          'word-reading sessions on approved Android tablets. Participant '
          'records remain on the device; this browser build is read-only.',
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _metrics(BuildContext context, BundledItemCatalog catalog) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final columns = available < 520 ? 2 : available < 900 ? 2 : 4;
        const gap = 10.0;
        final cardWidth = (available - gap * (columns - 1)) / columns;
        final metrics = <_MetricData>[
          _MetricData(
            value: catalog.realWords.length.toString(),
            label: 'Supplied real words',
            detail: 'Source list validated',
            color: AppTheme.tealDark,
          ),
          _MetricData(
            value: catalog.nonWordCandidateCount.toString(),
            label: 'Non-word candidates',
            detail: catalog.approvedNonWordCount == 270
                ? 'Native review approved'
                : 'Awaiting written review',
            color: catalog.approvedNonWordCount == 270
                ? AppTheme.tealDark
                : AppTheme.coral,
          ),
          const _MetricData(
            value: '6',
            label: 'Required sessions',
            detail: 'Schedule awaits sign-off',
            color: AppTheme.deepInk,
          ),
          const _MetricData(
            value: '10 s',
            label: 'Stimulus display',
            detail: 'Requirements baseline',
            color: AppTheme.deepInk,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map((metric) => SizedBox(
                    width: cardWidth,
                    child: _MetricCard(metric: metric),
                  ))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _sessionEntryCard() {
    final readOnlyWeb = kIsWeb;
    final ready = AssessmentReleaseGate.current.isOpen;
    final enabled = _canCollectIdentifiers;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _SectionHeading(
              icon: Icons.assignment_ind_outlined,
              title: 'Participant and session entry',
              subtitle: 'Assessor-only workflow',
            ),
            const SizedBox(height: 18),
            if (readOnlyWeb)
              const _InlineNotice(
                text: 'The Vercel browser build is for interface review. '
                    'Do not enter participant identifiers here. Use the '
                    'installed Android tablet application for field work.',
              )
            else if (!ready)
              const _InlineNotice(
                text: 'The participant workflow is protected until the '
                    'signed study protocol, reviewed item bank, audio assets '
                    'and field-release approvals are installed. Fields remain '
                    'inactive; no participant information is stored.',
              ),
            const SizedBox(height: 16),
            _field(
              controller: _childIdController,
              label: 'Child ID',
              hint: 'Enter the study-issued child ID',
              enabled: enabled,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _confirmChildIdController,
              label: 'Confirm Child ID',
              hint: 'Enter the same ID again',
              enabled: enabled,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _childNameController,
              label: 'Child name (optional)',
              hint: 'Stored locally only; excluded from default export',
              enabled: enabled,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _assessorIdController,
              label: 'Assessor ID',
              hint: 'Enter your assigned assessor ID',
              enabled: enabled,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Session number',
                hintText: 'Suggested from the child’s local session history',
                border: OutlineInputBorder(),
              ),
              items: List<DropdownMenuItem<int>>.generate(
                StudyProtocol.sessionCount,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('Session ' + (index + 1).toString()),
                ),
              ),
              onChanged: null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start assessment session'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Session history, duplicate-session checks, supervisor '
              'authorisation and resume/restart will be connected to the '
              'encrypted local repository before field release.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _readinessCard(BundledItemCatalog? catalog) {
    final blockers = AssessmentReleaseGate.current.blockers;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _SectionHeading(
              icon: Icons.fact_check_outlined,
              title: 'Field-release status',
              subtitle: 'Verified prerequisites',
            ),
            const SizedBox(height: 18),
            _ReadinessLine(
              label: 'Real Kannada word source',
              value: catalog?.hasCompleteRealWordPool == true
                  ? '270 loaded'
                  : 'Not verified',
              complete: catalog?.hasCompleteRealWordPool == true,
            ),
            const SizedBox(height: 12),
            _ReadinessLine(
              label: 'Non-word bank',
              value: catalog?.approvedNonWordCount == 270
                  ? '270 approved'
                  : (catalog == null
                      ? 'Loading'
                      : catalog.approvedNonWordCount.toString() +
                          ' / 270 approved'),
              complete: catalog?.approvedNonWordCount == 270,
            ),
            const SizedBox(height: 12),
            const _ReadinessLine(
              label: 'Written protocol and allocation',
              value: 'Pending study-team sign-off',
              complete: false,
            ),
            const SizedBox(height: 12),
            const _ReadinessLine(
              label: 'Recorded Kannada instructions',
              value: 'Approval and clip packaging pending',
              complete: false,
            ),
            const SizedBox(height: 12),
            const _ReadinessLine(
              label: 'Android tablet acceptance',
              value: 'Pending target-device testing',
              complete: false,
            ),
            const Divider(height: 28),
            Text(
              blockers.length.toString() + ' release requirements remain open.',
              style: const TextStyle(
                color: AppTheme.coral,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The application will not create or run a participant session '
              'until its required approvals and assets are present.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _releaseNotice() {
    return const _InlineNotice(
      text: 'Research safeguard: the supplied non-word workbook contains '
          '270 candidates, but the current source marks them Pending. The '
          'application must not present them to children until the native '
          'Kannada reviewer and study team provide written approval.',
    );
  }

  Widget _errorCard(String message) {
    return Card(
      color: const Color(0xFFFFF0EF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'The bundled item catalogue could not be validated: ' + message,
          style: const TextStyle(color: AppTheme.coral),
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.value,
    required this.label,
    required this.detail,
    required this.color,
  });

  final String value;
  final String label;
  final String detail;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            metric.value,
            style: TextStyle(
              color: metric.color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            metric.label,
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.detail,
            style: const TextStyle(color: AppTheme.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadinessLine extends StatelessWidget {
  const _ReadinessLine({
    required this.label,
    required this.value,
    required this.complete,
  });

  final String label;
  final String value;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          complete ? Icons.check_circle_rounded : Icons.pending_outlined,
          color: complete ? AppTheme.teal : AppTheme.coral,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.deepInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E7),
        border: Border.all(color: const Color(0xFFF2E2C3)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF926B2A),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF765C2B),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualWebUpdateButton extends StatefulWidget {
  const _ManualWebUpdateButton();

  @override
  State<_ManualWebUpdateButton> createState() =>
      _ManualWebUpdateButtonState();
}

class _ManualWebUpdateButtonState extends State<_ManualWebUpdateButton> {
  bool _checking = false;

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final activated = await WebUpdateService.checkAndActivate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activated
              ? 'Application update activated.'
              : 'No new application update was found.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to check for application updates.')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _checking ? null : _refresh,
      icon: _checking
          ? const SizedBox.square(
              dimension: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 15),
      label: Text(_checking ? 'Checking' : 'Refresh app'),
    );
  }
}

class _ApkDownloadButton extends StatelessWidget {
  const _ApkDownloadButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Downloads the ARM64 debug-signed engineering preview. Not approved for participant data collection.',
      child: OutlinedButton.icon(
        onPressed: ApkDownloadService.openLatestAndroidPreview,
        icon: const Icon(Icons.android_rounded, size: 15),
        label: const Text('Download Android APK'),
      ),
    );
  }
}

class _ManualUpdateButton extends StatefulWidget {
  const _ManualUpdateButton();

  @override
  State<_ManualUpdateButton> createState() => _ManualUpdateButtonState();
}

class _ManualUpdateButtonState extends State<_ManualUpdateButton> {
  bool _checking = false;

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await const PlayUpdateService().checkAndApplyAvailableUpdate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to check for Android updates.')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _checking ? null : _refresh,
      icon: _checking
          ? const SizedBox.square(
              dimension: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.system_update_alt_rounded, size: 15),
      label: Text(_checking ? 'Checking' : 'Check update'),
    );
  }
}
