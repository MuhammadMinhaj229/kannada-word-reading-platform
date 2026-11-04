import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/app_theme.dart';

class ChildWelcomeScreen extends StatefulWidget {
  const ChildWelcomeScreen({
    required this.childId,
    required this.assessorId,
    super.key,
  });

  final String childId;
  final String assessorId;

  @override
  State<ChildWelcomeScreen> createState() => _ChildWelcomeScreenState();
}

class _ChildWelcomeScreenState extends State<ChildWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _enterImmersivePreview();
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
    _leaveImmersivePreview();
    super.dispose();
  }

  void _showPreviewNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ಪೂರ್ವವೀಕ್ಷಣೆ'),
        content: const Text(
          'ಈ ನಿರ್ಮಾಣವು ವಿನ್ಯಾಸದ ಪೂರ್ವವೀಕ್ಷಣೆ ಮಾತ್ರ. '
          'ಅನುಮೋದಿತ ಸೂಚನೆಗಳು, ಧ್ವನಿ ಮತ್ತು ಪದಪಟ್ಟಿ ಸೇರಿಸಿದ ನಂತರ '
          'ಮೌಲ್ಯಮಾಪನವನ್ನು ಪ್ರಾರಂಭಿಸಬಹುದು.',
          style: TextStyle(height: 1.5),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ಸರಿ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      body: SafeArea(
        child: Center(
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
                    child: Center(child: _WelcomeIllustration()),
                  ),
                  const SizedBox(width: 34),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'ಪದLab',
                          style: TextStyle(
                            color: AppTheme.tealDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'ನಮಸ್ಕಾರ!',
                          style: TextStyle(
                            color: AppTheme.deepInk,
                            fontSize: 49,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ಸಿದ್ಧರಿದ್ದೀರಾ?',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 27),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            onPressed: _showPreviewNotice,
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
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: const BoxDecoration(
        color: AppTheme.mint,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 164,
          height: 124,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2410283B),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 82,
          ),
        ),
      ),
    );
  }
}
