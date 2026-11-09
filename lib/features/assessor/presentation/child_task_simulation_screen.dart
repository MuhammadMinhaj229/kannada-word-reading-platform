import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// A non-participant simulation for exercising the child-facing interaction.
///
/// This screen uses synthetic placeholder strings and keeps responses in
/// widget memory. It never reads the approved item bank, opens the release
/// gate, creates a participant, or writes to SQLCipher.
class ChildTaskSimulationScreen extends StatefulWidget {
  const ChildTaskSimulationScreen({super.key, this.isActive = true});

  /// False while another assessor workspace tab is visible.
  final bool isActive;

  @override
  State<ChildTaskSimulationScreen> createState() =>
      _ChildTaskSimulationScreenState();
}

class _ChildTaskSimulationScreenState extends State<ChildTaskSimulationScreen>
    with WidgetsBindingObserver {
  static const int _practiceCount = 5;
  static const int _scoredCount = 10;
  static const int _milestoneEveryAnswers = 10;

  // These fixtures only exercise layout and scoring display. They are not
  // validated Kannada words/non-words and must never enter a study session.
  static const List<_QaStimulus> _stimuli = <_QaStimulus>[
    _QaStimulus('ಕುನಮೆ', isWord: true, isPractice: true),
    _QaStimulus('ತೊಪಲಿ', isWord: false, isPractice: true),
    _QaStimulus('ಜವೊಕು', isWord: true, isPractice: true),
    _QaStimulus('ಮಿರಗಾ', isWord: false, isPractice: true),
    _QaStimulus('ನುತಕೆ', isWord: true, isPractice: true),
    _QaStimulus('ಪೆಲುಮಿ', isWord: true),
    _QaStimulus('ದೊಕವಿ', isWord: false),
    _QaStimulus('ಮರಿತೋ', isWord: false),
    _QaStimulus('ಗುನಕಾ', isWord: true),
    _QaStimulus('ವೊನತಿ', isWord: true),
    _QaStimulus('ತಕಿಮು', isWord: false),
    _QaStimulus('ನೊಗುಪ', isWord: true),
    _QaStimulus('ಲಿಮೊಗ', isWord: false),
    _QaStimulus('ಕವತು', isWord: false),
    _QaStimulus('ಸುನಾರಿ', isWord: true),
  ];

  final Stopwatch _trialClock = Stopwatch();
  final List<_QaResponse> _responses = <_QaResponse>[];

  int _currentIndex = 0;
  bool _started = false;
  bool _showMilestone = false;
  bool _isComplete = false;
  bool _showResults = false;
  bool _trialReady = false;
  bool _wasInterrupted = false;

  _QaStimulus get _currentStimulus => _stimuli[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant ChildTaskSimulationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _interruptSimulation();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _interruptSimulation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trialClock.stop();
    super.dispose();
  }

  void _interruptSimulation() {
    if (!_started || _isComplete || _showResults || _wasInterrupted) return;
    _trialClock.stop();
    if (!mounted) return;
    setState(() {
      _wasInterrupted = true;
      _trialReady = false;
    });
  }

  void _startSimulation() {
    if (!widget.isActive || _wasInterrupted) return;
    setState(() {
      _started = true;
      _trialReady = false;
    });
    _startTrialClockAfterRender();
  }

  /// Start RT only after the new stimulus has completed its first frame.
  void _startTrialClockAfterRender() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.isActive ||
          !_started ||
          _wasInterrupted ||
          _showMilestone ||
          _isComplete ||
          _showResults) {
        return;
      }
      _trialClock
        ..stop()
        ..reset()
        ..start();
      setState(() => _trialReady = true);
    });
  }

  void _recordAnswer(bool selectedWord) {
    if (!widget.isActive ||
        !_started ||
        !_trialReady ||
        !_trialClock.isRunning ||
        _wasInterrupted ||
        _showMilestone ||
        _isComplete ||
        _showResults) {
      return;
    }

    _trialClock.stop();
    _responses.add(
      _QaResponse(
        selectedWord: selectedWord,
        reactionTimeMs: _trialClock.elapsedMilliseconds,
      ),
    );

    if (_currentIndex == _stimuli.length - 1) {
      setState(() => _isComplete = true);
      return;
    }

    setState(() {
      _currentIndex += 1;
      _trialReady = false;
      _showMilestone = _responses.length % _milestoneEveryAnswers == 0;
    });
    if (!_showMilestone) {
      _startTrialClockAfterRender();
    }
  }

  void _resetSimulation() {
    _trialClock
      ..stop()
      ..reset();
    setState(() {
      _responses.clear();
      _currentIndex = 0;
      _started = false;
      _showMilestone = false;
      _isComplete = false;
      _showResults = false;
      _trialReady = false;
      _wasInterrupted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _simulationNotice(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _brandHeader(context),
                        const SizedBox(height: 22),
                        _buildStage(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simulationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: const Color(0xFFFFE9E2),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.science_outlined, color: Color(0xFF9F4938), size: 17),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'SIMULATION ONLY  •  SYNTHETIC DATA  •  NOT A PARTICIPANT SESSION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E3D30),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ಪದLab',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Text(
                'KANNADA WORD TASK',
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
        if (_started && !_isComplete && !_showResults) _progressPill(),
      ],
    );
  }

  Widget _progressPill() {
    final practice = _currentStimulus.isPractice;
    final phaseCount =
        practice ? _currentIndex + 1 : _currentIndex - _practiceCount + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.mint,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        practice
            ? 'ಅಭ್ಯಾಸ  $phaseCount / $_practiceCount'
            : 'ಮುಖ್ಯ ಹಂತ  $phaseCount / $_scoredCount',
        style: const TextStyle(
          color: AppTheme.tealDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    if (_wasInterrupted) return _buildInterrupted(context);
    if (_showResults) return _buildResults(context);
    if (_isComplete) return _buildCompletion(context);
    if (_showMilestone) return _buildMilestone(context);
    if (!_started) return _buildWelcome(context);
    return _buildTrial(context);
  }

  Widget _buildWelcome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.teal,
                  size: 46,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'ಬನ್ನಿ, ಪದಗಳನ್ನು ನೋಡೋಣ!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ಒಂದು ಅಕ್ಷರಗಳ ಗುಂಪನ್ನು ನೋಡಿ. ಅದು ನಿಜವಾದ ಕನ್ನಡ ಪದವೇ ಎಂದು '
                'ಯೋಚಿಸಿ, “ಪದ” ಅಥವಾ “ಪದವಲ್ಲ” ಆಯ್ಕೆಮಾಡಿ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 15,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'ಈ ಪರೀಕ್ಷಾ ಓಟದಲ್ಲಿ',
                  style: TextStyle(
                    color: AppTheme.deepInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const _InfoLine(
                  icon: Icons.lightbulb_outline_rounded,
                  text: '5 ಅಭ್ಯಾಸ ಕಾರ್ಡ್‌ಗಳು',
                ),
                const SizedBox(height: 8),
                const _InfoLine(
                  icon: Icons.style_outlined,
                  text: '10 ಮಾದರಿ ಕಾರ್ಡ್‌ಗಳು',
                ),
                const SizedBox(height: 8),
                const _InfoLine(
                  icon: Icons.lock_outline_rounded,
                  text: 'ಉತ್ತರಿಸಿದ ತಕ್ಷಣ ಸರಿಯೇ/ತಪ್ಪೇ ಎಂಬ ಸೂಚನೆ ಇರುವುದಿಲ್ಲ.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'This QA run uses synthetic interface fixtures only. '
                  'It is not the approved study item set.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _startSimulation,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ಪ್ರಾರಂಭಿಸೋಣ'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrial(BuildContext context) {
    final stimulus = _currentStimulus;
    final practice = stimulus.isPractice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              practice ? Icons.school_outlined : Icons.auto_awesome_outlined,
              color: AppTheme.tealDark,
            ),
            const SizedBox(width: 8),
            Text(
              practice ? 'ಅಭ್ಯಾಸ' : 'ಪದಗಳ ಆಯ್ಕೆ',
              style: const TextStyle(
                color: AppTheme.tealDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${_responses.length} / ${_stimuli.length}',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_responses.length + 1) / _stimuli.length,
            minHeight: 7,
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
          // Do not animate scored stimulus onset: the response clock starts
          // after this stable text has completed its first rendered frame.
          child: Center(
            child: Text(
              stimulus.text,
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
                    onPressed: _trialReady ? () => _recordAnswer(true) : null,
                    style: _choiceStyle(),
                    child: const Text('ಪದ'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FilledButton(
                    onPressed: _trialReady ? () => _recordAnswer(false) : null,
                    style: _choiceStyle(),
                    child: const Text('ಪದವಲ್ಲ'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          practice
              ? 'ಅಭ್ಯಾಸ ಹಂತ: ಉತ್ತರಿಸಿದ ನಂತರ ಮುಂದಿನ ಕಾರ್ಡ್ ಕಾಣಿಸುತ್ತದೆ.'
              : 'ಕಾರ್ಡ್‌ಗಳನ್ನು ಒಂದೊಂದಾಗಿ ನೋಡಿ ನಿಮ್ಮ ಆಯ್ಕೆಯನ್ನು ಮಾಡಿ.',
          textAlign: TextAlign.center,
          style: const TextStyle(
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

  Widget _buildMilestone(BuildContext context) {
    return _MessagePanel(
      icon: Icons.stars_rounded,
      title: '10 ಉತ್ತರಗಳು ಪೂರ್ಣಗೊಂಡಿವೆ!',
      message: 'ಮುಂದಿನ ಕಾರ್ಡ್‌ಗೆ ಹೋಗೋಣ.',
      actionLabel: 'ಮುಂದುವರಿಸು',
      onAction: () {
        setState(() {
          _showMilestone = false;
          _trialReady = false;
        });
        _startTrialClockAfterRender();
      },
      secondary: 'Neutral progress milestone — QA simulation only.',
    );
  }

  Widget _buildInterrupted(BuildContext context) {
    return _MessagePanel(
      icon: Icons.pause_circle_outline_rounded,
      title: 'QA run interrupted',
      message:
          'This run was stopped because the task lost focus. '
          'To keep response-time measurements valid, start a fresh QA run.',
      actionLabel: 'Restart QA run',
      onAction: _resetSimulation,
      secondary: 'Previous responses remain visible only in this temporary '
          'screen until you restart. Nothing was saved.',
    );
  }

  Widget _buildCompletion(BuildContext context) {
    return _MessagePanel(
      icon: Icons.auto_awesome_rounded,
      title: 'ಈ ಸಣ್ಣ ಕಾರ್ಯ ಮುಗಿದಿದೆ.',
      message: 'ಧನ್ಯವಾದಗಳು! ನಿಮ್ಮ ಉತ್ತರಗಳನ್ನು ಈಗ ಉಳಿಸಲಾಗುವುದಿಲ್ಲ.',
      actionLabel: 'Assessor results ನೋಡಿ',
      onAction: () => setState(() => _showResults = true),
      secondary: 'The child-facing flow does not display correctness or scores.',
      extraAction: OutlinedButton(
        onPressed: _resetSimulation,
        child: const Text('ಮತ್ತೊಮ್ಮೆ ಪರೀಕ್ಷಿಸಿ'),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final scored = _responses.asMap().entries.where(
          (entry) => !_stimuli[entry.key].isPractice,
        ).toList(growable: false);
    final correct = scored
        .where((entry) => entry.value.selectedWord == _stimuli[entry.key].isWord)
        .length;
    final meanRt = scored.isEmpty
        ? 0
        : (scored.fold<int>(
                  0,
                  (sum, entry) => sum + entry.value.reactionTimeMs,
                ) /
                scored.length)
            .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Assessor QA results',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Simulation only. These are not participant records or validated '
          'research scores.',
          style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 20) / 3;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: width,
                  child: _ResultMetric(
                    label: 'Scored answers',
                    value: '${scored.length} / $_scoredCount',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ResultMetric(
                    label: 'Correct (QA key)',
                    value: '$correct / ${scored.length}',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ResultMetric(
                    label: 'Mean response time',
                    value: '$meanRt ms',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Trial-by-trial inspection',
                  style: TextStyle(
                    color: AppTheme.deepInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ..._responses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final response = entry.value;
                  final stimulus = _stimuli[index];
                  return _ResultRow(
                    number: index + 1,
                    stimulus: stimulus,
                    response: response,
                    isCorrect: response.selectedWord == stimulus.isWord,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () => setState(() => _showResults = false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Completion screen'),
            ),
            FilledButton.icon(
              onPressed: _resetSimulation,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Run again'),
            ),
          ],
        ),
      ],
    );
  }
}

class _QaStimulus {
  const _QaStimulus(
    this.text, {
    required this.isWord,
    this.isPractice = false,
  });

  final String text;
  final bool isWord;
  final bool isPractice;
}

class _QaResponse {
  const _QaResponse({
    required this.selectedWord,
    required this.reactionTimeMs,
  });

  final bool selectedWord;
  final int reactionTimeMs;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppTheme.tealDark, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
    this.extraAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String secondary;
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: <Widget>[
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: AppTheme.tealDark, size: 42),
            ),
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
            if (extraAction != null) ...<Widget>[
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: extraAction!),
            ],
            const SizedBox(height: 12),
            Text(
              secondary,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.tealDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.number,
    required this.stimulus,
    required this.response,
    required this.isCorrect,
  });

  final int number;
  final _QaStimulus stimulus;
  final _QaResponse response;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final selected = response.selectedWord ? 'ಪದ' : 'ಪದವಲ್ಲ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '#$number  ${stimulus.isPractice ? 'Practice' : 'Scored'}',
                style: const TextStyle(
                  color: AppTheme.tealDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                stimulus.isPractice
                    ? 'Not scored'
                    : isCorrect
                        ? 'Correct (QA key)'
                        : 'Incorrect (QA key)',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stimulus.text,
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selected: $selected  •  QA key: ${stimulus.isWord ? 'Word' : 'Non-word'}  •  '
            'RT: ${response.reactionTimeMs} ms',
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
