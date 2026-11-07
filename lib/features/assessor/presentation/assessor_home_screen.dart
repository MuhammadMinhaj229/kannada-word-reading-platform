import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/assessment_release_gate.dart';
import '../../../core/config/study_protocol.dart';
import '../../../core/update/play_update_service.dart';
import '../../child/presentation/child_welcome_screen.dart';

class AssessorHomeScreen extends StatelessWidget {
  const AssessorHomeScreen({
    required this.demoMode,
    super.key,
  });

  /// Synthetic interaction mode is enabled only by an explicit build flag.
  /// It never asks for or stores participant identifiers.
  final bool demoMode;

  void _openDemo(BuildContext context) {
    if (!demoMode) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChildWelcomeScreen(
          childId: 'DEMO-CHILD',
          assessorId: 'DEMO-ASSESSOR',
          enableDevicePresentation: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < 900 || viewport.height < 700;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 34,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _topBar(context),
                  const SizedBox(height: 22),
                  Expanded(
                    child: compact
                        ? SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                _introduction(context),
                                const SizedBox(height: 18),
                                _launchPanel(context),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 11,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _introduction(context),
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 10,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _launchPanel(context),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;

    final brand = Row(
      children: <Widget>[
        const _BrandMark(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ಪದLab',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Text(
                'KANNADA WORD READING ASSESSMENT',
                softWrap: true,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final statuses = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        const _StatusPill(
          icon: Icons.cloud_off_rounded,
          label: 'OFFLINE-FIRST',
          color: AppTheme.teal,
        ),
        _StatusPill(
          icon: demoMode ? Icons.science_outlined : Icons.lock_outline_rounded,
          label: demoMode ? 'SYNTHETIC DEMO' : 'FIELD RELEASE LOCKED',
          color: AppTheme.coral,
        ),
        if (!kIsWeb &&
            !kDebugMode &&
            defaultTargetPlatform == TargetPlatform.android &&
            AppConfig.playUpdatesEnabled)
          const _ManualUpdateButton(),
      ],
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          brand,
          const SizedBox(height: 12),
          statuses,
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: brand),
        const SizedBox(width: 16),
        statuses,
      ],
    );
  }

  Widget _introduction(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'ASSESSOR WORKSPACE',
            style: TextStyle(
              color: AppTheme.tealDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'A calm, consistent\nassessment experience.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'An offline-first Android tablet application for administering '
          'the Kannada word-reading task and safeguarding every response '
          'on the device.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.muted,
              ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 420
                ? 1
                : constraints.maxWidth < 620
                    ? 2
                    : 3;
            final width =
                (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MetricCard(
                  width: width,
                  value: '${StudyProtocol.sessionCount}',
                  label: 'SESSIONS',
                  detail: 'Requested study structure',
                ),
                _MetricCard(
                  width: width,
                  value: '${StudyProtocol.presentationsPerSession}',
                  label: 'PRESENTATIONS',
                  detail: 'Per session',
                ),
                _MetricCard(
                  width: width,
                  value:
                      '${StudyProtocol.practicePresentationsPerSession} + ${StudyProtocol.testPresentationsPerSession}',
                  label: 'PRACTICE + TEST',
                  detail: 'Per requirements draft',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _notice(
          color: const Color(0xFFFFF7E7),
          border: const Color(0xFFF2E2C3),
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF926B2A),
          text: demoMode
              ? 'Synthetic review mode. The examples are not approved study '
                  'stimuli. Do not enter participant details or use this build '
                  'to collect research data.'
              : 'Participant administration is disabled. The signed study '
                  'protocol, approved Kannada item bank, language assets and '
                  'device acceptance are not present in this build.',
          textColor: const Color(0xFF765C2B),
        ),
        const SizedBox(height: 12),
        const Text(
          'Protocol baseline: ${StudyProtocol.requirementsVersion}. '
          'The session schedule remains subject to study-team confirmation.',
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _launchPanel(BuildContext context) {
    if (demoMode) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _PanelHeading(
                icon: Icons.science_outlined,
                title: 'Synthetic interaction preview',
                subtitle: 'No participant data is requested or saved.',
              ),
              const SizedBox(height: 18),
              const Text(
                'Walk through the sample child flow to review the layout, '
                'touch targets, progress and transitions.',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _openDemo(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Launch synthetic demo'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Demo IDs are fixed placeholders. This mode does not create '
                'a child record, session, trial record or export.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final blockers = AssessmentReleaseGate.current.blockers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _PanelHeading(
              icon: Icons.lock_outline_rounded,
              title: 'Participant assessment locked',
              subtitle: 'No participant workflow is available in this build.',
            ),
            const SizedBox(height: 16),
            _notice(
              color: const Color(0xFFFFF7E7),
              border: const Color(0xFFF2E2C3),
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF926B2A),
              text: 'This is a deliberate safety lock. Do not enter child '
                  'identifiers or conduct a research session until every '
                  'release requirement has an approved reference.',
              textColor: const Color(0xFF765C2B),
            ),
            const SizedBox(height: 18),
            Text(
              'RELEASE BLOCKERS (${blockers.length})',
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
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
      ),
    );
  }

  Widget _notice({
    required Color color,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
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

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
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
            borderRadius: BorderRadius.circular(12),
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
                style: Theme.of(context).textTheme.titleLarge,
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.value,
    required this.label,
    required this.detail,
  });

  final double width;
  final String value;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.tealDark,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(color: AppTheme.muted, fontSize: 10),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.teal,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        color: Colors.white,
        size: 27,
      ),
    );
  }
}


/// A deliberate update check shown only on a Play-installed Android release.
/// The assessor can use it from the idle home screen, never from a trial view.
class _ManualUpdateButton extends StatefulWidget {
  const _ManualUpdateButton();

  @override
  State<_ManualUpdateButton> createState() => _ManualUpdateButtonState();
}

class _ManualUpdateButtonState extends State<_ManualUpdateButton> {
  bool _checking = false;

  Future<void> _refreshUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final result =
          await const PlayUpdateService().checkAndApplyAvailableUpdate();
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _checking ? null : _refreshUpdates,
      icon: _checking
          ? const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 16),
      label: Text(_checking ? 'Checking…' : 'Refresh updates'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.tealDark,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppTheme.line),
      ),
    );
  }
}
