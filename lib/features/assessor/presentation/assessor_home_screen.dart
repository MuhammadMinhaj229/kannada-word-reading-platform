import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/assessment_release_gate.dart';
import '../../../core/update/apk_download_service.dart';
import '../../../core/update/play_update_service.dart';
import '../../../core/update/web_update_service.dart';
import '../../assessment/data/bundled_item_catalog.dart';

/// Assessor landing page for the shared Flutter Web and Android workspace.
///
/// Participant capture is intentionally absent while the signed release gate
/// is closed. This page exposes the review tools that are safe to use now.
class AssessorHomeScreen extends StatefulWidget {
  const AssessorHomeScreen({
    super.key,
    required this.onOpenTaskPreview,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenTaskPreview;
  final VoidCallback onOpenSettings;

  @override
  State<AssessorHomeScreen> createState() => _AssessorHomeScreenState();
}

class _AssessorHomeScreenState extends State<AssessorHomeScreen> {
  late final Future<BundledItemCatalog> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = BundledItemCatalog.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 860;
            final horizontalPadding = compact ? 16.0 : 30.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 18 : 28,
                horizontalPadding,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _header(context),
                      const SizedBox(height: 28),
                      _intro(context),
                      const SizedBox(height: 18),
                      _workspaceStatusCard(),
                      const SizedBox(height: 18),
                      _catalogueOverview(),
                      const SizedBox(height: 24),
                      _sectionTitle(
                        context,
                        'Assessor tools',
                        'Open the working review areas',
                      ),
                      const SizedBox(height: 12),
                      _toolCards(),
                      const SizedBox(height: 24),
                      _releaseReadinessCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 560;
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

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        const _StatusPill(
          icon: Icons.cloud_off_rounded,
          label: 'OFFLINE-CAPABLE',
          color: AppTheme.teal,
        ),
        _StatusPill(
          icon: kIsWeb ? Icons.language_rounded : Icons.phone_android_rounded,
          label: kIsWeb ? 'ONLINE REVIEW' : 'ANDROID BUILD',
          color: AppTheme.tealDark,
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
          actions,
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: identity),
        const SizedBox(width: 16),
        Flexible(child: actions),
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
        const SizedBox(height: 16),
        Text(
          'Assessor workspace',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.deepInk,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Review the supplied Kannada item bank, inspect source metadata, '
          'check the task flow and monitor what remains before field release. '
          'The Web and Android applications are built from the same Flutter '
          'codebase.',
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _workspaceStatusCard() {
    final isBrowser = kIsWeb;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2DE),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF946A2B),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Participant sessions are locked',
                    style: const TextStyle(
                      color: AppTheme.deepInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isBrowser
                        ? 'This browser workspace is for assessor review and '
                            'task-flow checking. It does not accept participant '
                            'identifiers or save research responses.'
                        : 'The participant workflow remains locked until the '
                            'signed protocol, approved item bank, audio package '
                            'and field-release requirements are verified.',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogueOverview() {
    return FutureBuilder<BundledItemCatalog>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'The bundled Kannada catalogue could not be validated. '
                '${snapshot.error ?? ''}',
                style: const TextStyle(color: AppTheme.coral),
              ),
            ),
          );
        }
        final catalog = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 520 ? 2 : 3;
            final metricWidth =
                (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: metricWidth,
                  child: _MetricCard(
                    value: catalog.realWords.length.toString(),
                    label: 'Supplied real words',
                    icon: Icons.menu_book_rounded,
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: _MetricCard(
                    value: catalog.suppliedNonWordCount.toString(),
                    label: 'Candidates for review',
                    icon: Icons.fact_check_outlined,
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: _MetricCard(
                    value: catalog.approvedNonWordCount.toString(),
                    label: 'Approved candidates',
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _toolCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final width = compact ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            SizedBox(
              width: width,
              child: _ToolCard(
                icon: Icons.library_books_outlined,
                title: 'Item bank & settings',
                description: 'Search the supplied word list and pending '
                    'candidates, inspect metadata, audio status and release '
                    'requirements.',
                buttonLabel: 'Open item bank',
                onPressed: widget.onOpenSettings,
              ),
            ),
            SizedBox(
              width: width,
              child: _ToolCard(
                icon: Icons.touch_app_outlined,
                title: 'Task-flow preview',
                description: 'Run the child-facing interaction sequence and '
                    'verify touch targets, navigation and preview responses. '
                    'Nothing is saved as a participant record.',
                buttonLabel: 'Open task preview',
                onPressed: widget.onOpenTaskPreview,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _releaseReadinessCard() {
    final blockers = AssessmentReleaseGate.current.blockers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.fact_check_outlined, color: AppTheme.coral),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Field-release readiness',
                    style: TextStyle(
                      color: AppTheme.deepInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${blockers.length} open',
                  style: const TextStyle(
                    color: AppTheme.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The application does not unlock participant sessions from a '
              'browser setting or local switch. A signed institutional release '
              'is required.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onOpenSettings,
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Review release requirements'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppTheme.teal, size: 19),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.deepInk,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.deepInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
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
          'Downloads the ARM64 offline Android engineering build. It is debug-signed and is not approved for participant field use.',
      child: OutlinedButton.icon(
        onPressed: ApkDownloadService.openLatestAndroidPreview,
        icon: const Icon(Icons.android_rounded, size: 15),
        label: const Text('Android APK'),
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
