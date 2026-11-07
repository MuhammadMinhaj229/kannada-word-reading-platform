import 'package:flutter_tts/flutter_tts.dart';

/// Device-provided Kannada speech used only for synthetic review/demo flows.
///
/// This is not a substitute for the locally bundled, PHFI/CDLR-approved
/// instruction recordings required by the research protocol. The participant
/// workflow is release-locked and must not depend on network TTS.
class KannadaSpeechService {
  KannadaSpeechService._();

  static final KannadaSpeechService instance = KannadaSpeechService._();

  final FlutterTts _tts = FlutterTts();
  Future<bool>? _availability;

  bool enabled = true;

  Future<bool> isKannadaVoiceAvailable({bool refresh = false}) {
    if (refresh) _availability = null;
    return _availability ??= _checkAvailability();
  }

  Future<bool> _checkAvailability() async {
    try {
      final result = await _tts.isLanguageAvailable('kn-IN');
      return result == true || result == 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> speakPreview(String phrase) async {
    if (!enabled) return;
    if (!await isKannadaVoiceAvailable()) {
      throw StateError(
        'A Kannada speech voice is not available on this device. '
        'Install an offline Kannada voice or keep preview audio disabled.',
      );
    }

    await _tts.setLanguage('kn-IN');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    final result = await _tts.speak(phrase);
    if (result != 1) {
      throw StateError('The device Kannada speech preview could not start.');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Stopping unavailable speech must not break navigation or app disposal.
    }
  }
}
