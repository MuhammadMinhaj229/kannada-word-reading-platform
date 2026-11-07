import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// A synthetic, non-persistent interaction demo.
///
/// These examples exercise the child interface only. They are not approved
/// research stimuli and must never be used to collect participant data.
class DemoGameScreen extends StatefulWidget {
  const DemoGameScreen({super.key});

  @override
  State<DemoGameScreen> createState() => _DemoGameScreenState();
}

class _DemoGameScreenState extends State<DemoGameScreen> {
  static const _prompts = <_DemoPrompt>[
    _DemoPrompt(text: 'ಮನೆ', isWord: true),
    _DemoPrompt(text: 'ಜುಪ್ಲಾ', isWord: false),
    _DemoPrompt(text: 'ಮಳೆ', isWord: true),
    _DemoPrompt(text: 'ನೊಗಮಿ', isWord: false),
  ];

  final Stopwatch _stopwatch = Stopwatch();
  final List<_DemoResponse> _responses = <_DemoResponse>[];

  int _promptIndex = 0;
  bool? _selectedIsWord;
  bool _completed = false;

  _DemoPrompt get _currentPrompt => _prompts[_promptIndex];

  @override
  void initState() {
    super.initState();
    _startClock();
  }

  void _startClock() {
    _stopwatch
      ..reset()
      ..start();
  }

  void _submitAnswer(bool selectedIsWord) {
    if (_selectedIsWord != null || _completed) return;

    _stopwatch.stop();
    final response = _DemoResponse(
      selectedIsWord: selectedIsWord,
      expectedIsWord: _currentPrompt.isWord,
      reactionTimeMs: _stopwatch.elapsedMilliseconds,
    );

    setState(() {
      _selectedIsWord = selectedIsWord;
      _responses.add(response);
    });
  }

  void _continue() {
    if (_selectedIsWord == null || _completed) return;

    if (_promptIndex == _prompts.length - 1) {
      setState(() => _completed = true);
      return;
    }

    setState(() {
      _promptIndex += 1;
      _selectedIsWord = null;
      _startClock();
    });
  }

  void _restart() {
    setState(() {
      _promptIndex = 0;
      _selectedIsWord = null;
      _completed = false;
      _responses.clear();
      _startClock();
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 760 || constraints.maxHeight < 560;
            final horizontalPadding = compact ? 16.0 : 32.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: compact ? 18 : 28,
                      ),
                      child: _completed
                          ? _completionContent()
                          : _gameContent(compact: compact),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _gameContent({required bool compact}) {
    final progress = (_promptIndex + (_selectedIsWord == null ? 0 : 1)) /
        _prompts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _topBar(),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'ಮಾದರಿ ${_promptIndex + 1} / ${_prompts.length}',
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'SAMPLE FLOW',
              style: TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            backgroundColor: AppTheme.line,
            color: AppTheme.teal,
          ),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 18 : 32,
              vertical: compact ? 24 : 34,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'ಈ ಪದ ನಿಜವಾದ ಪದವೇ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentPrompt.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.deepInk,
                    fontSize: compact ? 46 : 60,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ಇದು ಕೇವಲ ಮಾದರಿ ಪ್ರದರ್ಶನ. ಈ ಪದಗಳು ಅನುಮೋದಿತ ಪರೀಕ್ಷಾ ಪದಗಳಲ್ಲ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (_selectedIsWord == null)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 62,
                          child: FilledButton(
                            key: const ValueKey('demo-word-answer'),
                            onPressed: () => _submitAnswer(true),
                            child: const Text(
                              'ಪದ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 62,
                          child: OutlinedButton(
                            key: const ValueKey('demo-nonword-answer'),
                            onPressed: () => _submitAnswer(false),
                            child: const Text(
                              'ಪದವಲ್ಲ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  _answerFeedback(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _DemoSafetyNotice(),
      ],
    );
  }

  Widget _topBar() {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'ಹಿಂದೆ',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'ಪದLab',
            style: TextStyle(
              color: AppTheme.tealDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const _DemoTag(),
      ],
    );
  }

  Widget _answerFeedback() {
    final response = _responses.last;
    final wasCorrect =
        response.selectedIsWord == response.expectedIsWord;
    return Column(
      children: <Widget>[
        Icon(
          wasCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
          color: wasCorrect ? AppTheme.teal : AppTheme.coral,
          size: 34,
        ),
        const SizedBox(height: 8),
        Text(
          wasCorrect ? 'ಚೆನ್ನಾಗಿದೆ!' : 'ಮಾದರಿ ಉತ್ತರ ತೋರಿಸಲಾಗಿದೆ',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'ಪ್ರದರ್ಶನ ಪ್ರತಿಕ್ರಿಯೆ: ${response.reactionTimeMs} ms',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            key: const ValueKey('demo-next'),
            onPressed: _continue,
            child: Text(
              _promptIndex == _prompts.length - 1
                  ? 'ಪ್ರದರ್ಶನ ಫಲಿತಾಂಶ'
                  : 'ಮುಂದಿನ ಮಾದರಿ',
            ),
          ),
        ),
      ],
    );
  }

  Widget _completionContent() {
    final correctCount = _responses
        .where(
          (response) => response.selectedIsWord == response.expectedIsWord,
        )
        .length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _topBar(),
        const SizedBox(height: 42),
        const Icon(
          Icons.task_alt_rounded,
          color: AppTheme.teal,
          size: 72,
        ),
        const SizedBox(height: 18),
        const Text(
          'ಪ್ರದರ್ಶನ ಪೂರ್ಣಗೊಂಡಿದೆ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.deepInk,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You completed the sample interaction.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Text(
                  '$correctCount / ${_prompts.length}',
                  style: const TextStyle(
                    color: AppTheme.tealDark,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'DEMO RESPONSES MATCHED',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'These sample responses were held in memory only. '
                  'Nothing was saved or exported.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('demo-restart'),
          onPressed: _restart,
          child: const Text('ಮತ್ತೊಮ್ಮೆ ಪ್ರದರ್ಶಿಸಿ'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('ಮುಖ್ಯ ಪರದೆಗೆ ಹಿಂತಿರುಗಿ'),
        ),
        const SizedBox(height: 16),
        const _DemoSafetyNotice(),
      ],
    );
  }
}

class _DemoPrompt {
  const _DemoPrompt({required this.text, required this.isWord});

  final String text;
  final bool isWord;
}

class _DemoResponse {
  const _DemoResponse({
    required this.selectedIsWord,
    required this.expectedIsWord,
    required this.reactionTimeMs,
  });

  final bool selectedIsWord;
  final bool expectedIsWord;
  final int reactionTimeMs;
}

class _DemoTag extends StatelessWidget {
  const _DemoTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'DEMO ONLY',
        style: TextStyle(
          color: AppTheme.coral,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DemoSafetyNotice extends StatelessWidget {
  const _DemoSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2E2C3)),
      ),
      child: const Text(
        'ಪೂರ್ವವೀಕ್ಷಣೆ ಮಾತ್ರ: ಅನುಮೋದಿತ ಪದಪಟ್ಟಿ ಮತ್ತು ಅಧ್ಯಯನ ನಿಯಮಗಳು '
        'ಸೇರಿಸುವವರೆಗೆ ಮಕ್ಕಳ ಪರೀಕ್ಷೆಗೆ ಬಳಸಬೇಡಿ. ಈ ಪ್ರದರ್ಶನದ ಉತ್ತರಗಳು ಉಳಿಯುವುದಿಲ್ಲ.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF765C2B),
          fontSize: 11,
          height: 1.5,
        ),
      ),
    );
  }
}
