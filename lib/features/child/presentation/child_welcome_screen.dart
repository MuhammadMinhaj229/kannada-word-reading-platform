import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/app_theme.dart';
import '../../../core/audio/kannada_speech_service.dart';
import 'demo_game_screen.dart';

class ChildWelcomeScreen extends StatefulWidget {
  const ChildWelcomeScreen({
    required this.childId,
    required this.assessorId,
    this.enableDevicePresentation = !kIsWeb,
    super.key,
  });

  final String childId;
  final String assessorId;
  final bool enableDevicePresentation;

  @override
  State<ChildWelcomeScreen> createState() => _ChildWelcomeScreenState();
}

class _ChildWelcomeScreenState extends State<ChildWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.enableDevicePresentation && !kIsWeb) {
      _enterImmersivePreview();
    }
  }

  Future<void> _enterImmersivePreview() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
  }

  Future<void> _leaveImmersivePreview() async {
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    if (widget.enableDevicePresentation && !kIsWeb) {
      _leaveImmersivePreview();
    }
    super.dispose();
  }

  Future<void> _startDemo() async {
    // This is a demo-only device speech fallback. Field instructions must use
    // the study team's approved local recordings, not synthesized speech.
    try {
      await KannadaSpeechService.instance.speakPreview(
        'ನಮಸ್ಕಾರ! ಪರದೆಯ ಮೇಲಿರುವ ಪದವನ್ನು ಗಮನಿಸಿ. ಇದು ನಿಜವಾದ ಪದವೇ ಅಥವಾ ಪದವಲ್ಲವೇ ಎಂದು ಆಯ್ಕೆಮಾಡಿ.',
      );
    } catch (_) {
      // Keep the visual demo usable when the device has no Kannada voice.
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DemoGameScreen(),
      ),
    );
  }

  Widget _welcomeCopy({required bool compact}) {
    final textAlignment =
        compact ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: textAlignment,
      children: <Widget>[
        Align(
          alignment: compact ? Alignment.center : Alignment.centerLeft,
          child: const Text(
            'ಪದLab',
            style: TextStyle(
              color: AppTheme.tealDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'ನಮಸ್ಕಾರ!',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: AppTheme.deepInk,
            fontSize: compact ? 42 : 52,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ಸಿದ್ಧರಿದ್ದೀರಾ?',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: compact ? 23 : 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 27),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            onPressed: _startDemo,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'ಮುಂದುವರಿಸಿ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'ಇದು ಪೂರ್ವವೀಕ್ಷಣೆ ಮಾತ್ರ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 760 || constraints.maxHeight < 540;
            if (compact) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const _WelcomeIllustration(size: 164),
                        const SizedBox(height: 22),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _welcomeCopy(compact: true),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 34,
                    vertical: 20,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        flex: 5,
                        child: Center(
                          child: _WelcomeIllustration(size: 260),
                        ),
                      ),
                      const SizedBox(width: 34),
                      Expanded(
                        flex: 6,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _welcomeCopy(compact: false),
                        ),
                      ),
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
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppTheme.mint,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.63,
          height: size * 0.48,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(size * 0.09),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2410283B),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: size * 0.31,
          ),
        ),
      ),
    );
  }
}
