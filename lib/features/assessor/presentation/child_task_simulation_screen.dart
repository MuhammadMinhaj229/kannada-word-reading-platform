import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../assessment/data/bundled_item_catalog.dart';

/// Child-facing task preview built from the supplied Kannada catalogue.
///
/// This screen is deliberately a preview: it uses real source words and
/// pending non-word candidates, but never creates participant records or
/// measures research reaction times. Participant sessions remain behind the
/// independent release gate.
class ChildTaskSimulationScreen extends StatefulWidget {
  const ChildTaskSimulationScreen({
    super.key,
    this.isActive = true,
    this.catalogFuture,
  });

  final bool isActive;

  /// Allows deterministic tests to inject a catalogue already loaded from the
  /// real bundled assets. Production callers omit this and load the bundle.
  final Future<BundledItemCatalog>? catalogFuture;

  @override
  State<ChildTaskSimulationScreen> createState() =>
      _ChildTaskSimulationScreenState();
}

class _ChildTaskSimulationScreenState extends State<ChildTaskSimulationScreen>
    with WidgetsBindingObserver {
  static const int _practiceCount = 5;
  static const int _previewTestCount = 10;
  static const int _rewardEvery = 10;

  late final Future<BundledItemCatalog> _catalogFuture;
  List<_PreviewStimulus> _stimuli = const <_PreviewStimulus>[];

  int _currentIndex = 0;
  int _answeredCount = 0;
  final List<_PreviewResponse> _responses = <_PreviewResponse>[];
  bool _started = false;
  bool _showMilestone = false;
  bool _complete = false;
  bool _interrupted = false;

  _PreviewStimulus? get _current =>
      _stimuli.isEmpty ? null : _stimuli[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _catalogFuture = widget.catalogFuture ?? BundledItemCatalog.load();
  }

  List<_PreviewStimulus> _buildPreviewStimuli(
    BundledItemCatalog catalog,
  ) {
    final items = <_PreviewStimulus>[];
    for (var index = 0; index < _practiceCount; index += 1) {
      final word = catalog.realWords[index];
      items.add(_PreviewStimulus(
        id: word.id,
        text: word.text,
        isPractice: true,
      ));
    }
    for (var index = 0; index < _previewTestCount ~/ 2; index += 1) {
      final realWord = catalog.realWords[_practiceCount + index];
      final nonWord = catalog.suppliedNonWordCandidates[index];
      items.add(_PreviewStimulus(
        id: realWord.id,
        text: realWord.text,
        isPractice: false,
      ));
      items.add(_PreviewStimulus(
        id: nonWord.id,
        text: nonWord.text,
        isPractice: false,
      ));
    }
    return List<_PreviewStimulus>.unmodifiable(items);
  }

  @override
  void didUpdateWidget(covariant ChildTaskSimulationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _interruptPreview();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _interruptPreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _interruptPreview() {
    if (!_started || _complete || _interrupted) return;
    if (!mounted) return;
    setState(() => _interrupted = true);
  }

  void _startPreview() {
    if (!widget.isActive || _interrupted || _stimuli.length !=
        _practiceCount + _previewTestCount) {
      return;
    }
    setState(() => _started = true);
  }

  void _answer({required bool selectedWord}) {
    if (!widget.isActive || !_started || _interrupted || _complete ||
        _showMilestone || _current == null) {
      return;
    }
    setState(() {
      _responses.add(_PreviewResponse(
        isPractice: _current!.isPractice,
        selectedWord: selectedWord,
      ));
      _answeredCount += 1;
      if (_currentIndex == _stimuli.length - 1) {
        _complete = true;
      } else {
        _currentIndex += 1;
        _showMilestone = _answeredCount % _rewardEvery == 0;
      }
    });
  }

  void _continueAfterMilestone() {
    setState(() => _showMilestone = false);
  }

  void _resetPreview() {
    setState(() {
      _currentIndex = 0;
      _answeredCount = 0;
      _responses.clear();
      _started = false;
      _showMilestone = false;
      _complete = false;
      _interrupted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: FutureBuilder<BundledItemCatalog>(
          future: _catalogFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _errorState(snapshot.error?.toString() ??
                  'The supplied Kannada catalogue could not be loaded.');
            }
            if (_stimuli.isEmpty) {
              try {
                _stimuli = _buildPreviewStimuli(snapshot.data!);
              } catch (error) {
                return _errorState(error.toString());
              }
            }
            if (_stimuli.length != _practiceCount + _previewTestCount) {
              return _errorState('The supplied catalogue does not contain enough preview items.');
            }
            return Column(
              children: <Widget>[
                _previewNotice(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: _buildStage(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _previewNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: const Color(0xFFEAF4F1),
      child: const Text(
        'TASK PREVIEW · REAL SUPPLIED WORDS + PENDING CANDIDATES · NO PARTICIPANT DATA',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.tealDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    if (_interrupted) return _interruptedStage();
    if (_complete) return _completionStage();
    if (_showMilestone) return _milestoneStage();
    if (!_started) return _welcomeStage(context);
    return _trialStage(context);
  }

  Widget _welcomeStage(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(compact ? 18 : 28),
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(compact ? 22 : 28),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: compact ? 68 : 88,
                height: compact ? 68 : 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 22 : 28),
                ),
                child: Center(
                  child: Text(
                    '🐘',
                    style: TextStyle(fontSize: compact ? 40 : 48),
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 18),
              Text(
                'ಬನ್ನಿ, ಪದಗಳ ಆಟ ಆಡೋಣ!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: compact ? 21 : null,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                'ಒಂದು ಕನ್ನಡ ಅಕ್ಷರಗಳ ಗುಂಪನ್ನು ನೋಡಿ. ಅದು ನಿಜವಾದ ಪದವೇ ಅಥವಾ ಪದವಲ್ಲವೇ ಎಂದು ಆಯ್ಕೆಮಾಡಿ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: compact ? 14 : 15,
                  height: compact ? 1.45 : 1.65,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'ಈ ಪೂರ್ವವೀಕ್ಷಣೆಯಲ್ಲಿ',
                  style: TextStyle(
                    color: AppTheme.deepInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const _InfoLine(
                  icon: Icons.school_outlined,
                  text: 'ನಿಮ್ಮ ನಿಜವಾದ ಪದಪಟ್ಟಿಯಿಂದ 5 ಅಭ್ಯಾಸ ಪದಗಳು',
                ),
                const SizedBox(height: 6),
                const _InfoLine(
                  icon: Icons.style_outlined,
                  text: 'ನಿಜವಾದ ಪದಗಳು ಮತ್ತು ಪರಿಶೀಲನೆ ಬಾಕಿಯಿರುವ ಅಭ್ಯರ್ಥಿಗಳ ಮಿಶ್ರಣ',
                ),
                const SizedBox(height: 6),
                const _InfoLine(
                  icon: Icons.lock_outline_rounded,
                  text: 'ಉತ್ತರಗಳು ದಾಖಲಾಗುವುದಿಲ್ಲ; ಸರಿಯೇ/ತಪ್ಪೇ ಎಂದು ತೋರಿಸುವುದಿಲ್ಲ.',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        FilledButton.icon(
          onPressed: _startPreview,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ಪ್ರಾರಂಭಿಸೋಣ'),
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 58 : 60),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _trialStage(BuildContext context) {
    final stimulus = _current!;
    final practice = stimulus.isPractice;
    final phaseNumber = practice
        ? _currentIndex + 1
        : _currentIndex - _practiceCount + 1;
    final phaseTotal = practice ? _practiceCount : _previewTestCount;
    final progress = _currentIndex + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.mint,
              child: Text('🐘', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                practice ? 'ಅಭ್ಯಾಸ ಮಾಡೋಣ!' : 'ಪದವನ್ನು ಗಮನಿಸಿ!',
                style: const TextStyle(
                  color: AppTheme.tealDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              practice
                  ? 'ಅಭ್ಯಾಸ $phaseNumber / $phaseTotal'
                  : 'ಆಟ $phaseNumber / $phaseTotal',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress / _stimuli.length,
            minHeight: 8,
            backgroundColor: AppTheme.line,
            color: AppTheme.teal,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'ಇದು ನಿಜವಾದ ಕನ್ನಡ ಪದವೇ?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(minHeight: 210),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.line),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A183247),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              stimulus.text,
              key: ValueKey<String>(stimulus.id),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ನಿಮ್ಮ ಉತ್ತರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 560
                ? constraints.maxWidth
                : (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: width,
                  child: FilledButton(
                    onPressed: () => _answer(selectedWord: true),
                    style: _choiceStyle(),
                    child: const Text('ಪದ'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FilledButton(
                    onPressed: () => _answer(selectedWord: false),
                    style: _choiceStyle(),
                    child: const Text('ಪದವಲ್ಲ'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'ಇದು ಪೂರ್ವವೀಕ್ಷಣೆ ಮಾತ್ರ. ಸಂಶೋಧನಾ ಉತ್ತರಗಳು ಅಥವಾ ಸಮಯವನ್ನು ದಾಖಲಿಸುವುದಿಲ್ಲ.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  ButtonStyle _choiceStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppTheme.teal,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 64),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      textStyle: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _milestoneStage() {
    return _MessagePanel(
      icon: Icons.stars_rounded,
      title: 'ಚೆನ್ನಾಗಿದೆ!',
      message: 'ನೀವು ಇನ್ನೂ ಐದು ಕಾರ್ಡ್‌ಗಳನ್ನು ನೋಡಿದ್ದೀರಿ.',
      actionLabel: 'ಮುಂದುವರಿಸು',
      onAction: _continueAfterMilestone,
      secondary: 'Preview milestone only — no study response is stored.',
    );
  }

  Widget _completionStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MessagePanel(
          icon: Icons.celebration_rounded,
          title: 'ಅದ್ಭುತ! ಪೂರ್ವವೀಕ್ಷಣೆ ಮುಗಿದಿದೆ.',
          message: 'ನೀವು ನಿಜವಾದ ಪದಪಟ್ಟಿಯೊಂದಿಗೆ ಆಟದ ಅನುಭವವನ್ನು ನೋಡಿದ್ದೀರಿ.',
          actionLabel: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
          onAction: _resetPreview,
          secondary: 'No participant record or assessment score was created.',
        ),
        const SizedBox(height: 14),
        _responseSummaryCard(),
      ],
    );
  }

  Widget _responseSummaryCard() {
    final wordSelections =
        _responses.where((response) => response.selectedWord).length;
    final nonWordSelections = _responses.length - wordSelections;
    final practiceSelections =
        _responses.where((response) => response.isPractice).length;
    final taskSelections = _responses.length - practiceSelections;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'PREVIEW RESPONSE SUMMARY',
              style: TextStyle(
                color: AppTheme.tealDark,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryLine(
              label: 'Word selected',
              value: wordSelections.toString(),
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              label: 'Not word selected',
              value: nonWordSelections.toString(),
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              label: 'Practice responses',
              value: practiceSelections.toString(),
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              label: 'Task-preview responses',
              value: taskSelections.toString(),
            ),
            const SizedBox(height: 12),
            const Text(
              'These selections are held only in this open preview. They are '
              'not persisted, exported or treated as participant research data.',
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

  Widget _interruptedStage() {
    return _MessagePanel(
      icon: Icons.pause_circle_outline_rounded,
      title: 'ಪೂರ್ವವೀಕ್ಷಣೆ ನಿಲ್ಲಿಸಲಾಗಿದೆ',
      message: 'ನೀವು ಬೇರೆ ಪರದೆಗೆ ಹೋದಾಗ ಈ ಪೂರ್ವವೀಕ್ಷಣೆಯನ್ನು ನಿಲ್ಲಿಸಲಾಗಿದೆ.',
      actionLabel: 'ಮತ್ತೆ ಪ್ರಾರಂಭಿಸಿ',
      onAction: _resetPreview,
      secondary: 'Preview only — nothing was saved.',
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Kannada catalogue could not be loaded.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PreviewResponse {
  const _PreviewResponse({
    required this.isPractice,
    required this.selectedWord,
  });

  final bool isPractice;
  final bool selectedWord;
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.deepInk,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _PreviewStimulus {
  const _PreviewStimulus({
    required this.id,
    required this.text,
    required this.isPractice,
  });

  final String id;
  final String text;
  final bool isPractice;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppTheme.teal, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.secondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.mint,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppTheme.tealDark, size: 64),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
          const SizedBox(height: 12),
          Text(
            secondary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
