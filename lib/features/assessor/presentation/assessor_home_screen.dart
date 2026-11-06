import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/config/study_protocol.dart';
import '../../child/presentation/child_welcome_screen.dart';

class AssessorHomeScreen extends StatefulWidget {
  const AssessorHomeScreen({super.key});

  @override
  State<AssessorHomeScreen> createState() => _AssessorHomeScreenState();
}

class _AssessorHomeScreenState extends State<AssessorHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childIdController = TextEditingController();
  final _confirmChildIdController = TextEditingController();
  final _assessorIdController = TextEditingController();
  final _childNameController = TextEditingController();

  @override
  void dispose() {
    _childIdController.dispose();
    _confirmChildIdController.dispose();
    _assessorIdController.dispose();
    _childNameController.dispose();
    super.dispose();
  }

  void _openPreview() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChildWelcomeScreen(
          childId: _childIdController.text.trim(),
          assessorId: _assessorIdController.text.trim(),
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
                horizontal: compact ? 20 : 34,
                vertical: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _topBar(context),
                  const SizedBox(height: 24),
                  Expanded(
                    child: compact
                        ? SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                _introduction(context),
                                const SizedBox(height: 18),
                                _participantForm(context),
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
                                  child: _participantForm(context),
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
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _BrandMark(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ಪದLab',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  narrow
                      ? 'KANNADA ASSESSMENT'
                      : 'KANNADA WORD READING ASSESSMENT',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (!narrow)
          const _StatusPill(
            icon: Icons.cloud_off_rounded,
            label: 'OFFLINE-FIRST',
            color: AppTheme.teal,
          ),
        const _StatusPill(
          icon: Icons.science_outlined,
          label: 'PREVIEW BUILD',
          color: AppTheme.coral,
        ),
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
          'A dedicated offline workspace for administering the Kannada '
          'word-reading task and safeguarding every response on the tablet.',
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
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MetricCard(
                  width: width,
                  value: '${StudyProtocol.sessionCount}',
                  label: 'SESSIONS',
                  detail: 'Across the study',
                ),
                _MetricCard(
                  width: width,
                  value: '${StudyProtocol.scoredItemsPerSession}',
                  label: 'SCORED ITEMS',
                  detail: 'Per session',
                ),
                _MetricCard(
                  width: width,
                  value: '${StudyProtocol.practiceItemsPerSession}',
                  label: 'PRACTICE',
                  detail: 'Before assessment',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF2E2C3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF926B2A), size: 19),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Development preview only. The approved item bank, '
                  'Kannada recordings and participant data workflow are '
                  'not enabled in this build.',
                  style: TextStyle(
                    color: Color(0xFF765C2B),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _participantForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: AppTheme.tealDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Prepare a child session',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Enter identifiers to preview the child interface.',
                          style: TextStyle(
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
              _field(
                controller: _childIdController,
                label: 'Child ID',
                hint: 'Enter study ID',
                icon: Icons.person_outline_rounded,
                validator: (value) => _required(value, 'Child ID'),
              ),
              const SizedBox(height: 11),
              _field(
                controller: _confirmChildIdController,
                label: 'Confirm Child ID',
                hint: 'Re-enter the same study ID',
                icon: Icons.verified_user_outlined,
                validator: (value) {
                  final error = _required(value, 'Confirm Child ID');
                  if (error != null) return error;
                  if (value!.trim() != _childIdController.text.trim()) {
                    return 'The Child IDs do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 11),
              _field(
                controller: _assessorIdController,
                label: 'Assessor ID',
                hint: 'Enter assessor ID',
                icon: Icons.assignment_ind_outlined,
                validator: (value) => _required(value, 'Assessor ID'),
              ),
              const SizedBox(height: 11),
              _field(
                controller: _childNameController,
                label: 'Child name (optional)',
                hint: 'Excluded from default exports',
                icon: Icons.face_outlined,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openPreview,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Preview child experience'),
                ),
              ),
              const SizedBox(height: 9),
              const Center(
                child: Text(
                  'Session registration and recovery are being built next.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        color: AppTheme.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.muted),
        isDense: true,
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
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
