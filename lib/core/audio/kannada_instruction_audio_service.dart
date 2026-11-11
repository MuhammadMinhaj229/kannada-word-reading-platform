import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Plays only locally bundled recordings that have a documented study-team
/// approval reference. This service deliberately has no text-to-speech path.
class KannadaInstructionAudioService {
  KannadaInstructionAudioService({
    AudioPlayer? player,
    AssetBundle? bundle,
  })  : _player = player ?? AudioPlayer(),
        _bundle = bundle ?? rootBundle;

  static const String manifestAsset = 'assets/audio/audio_manifest.json';

  final AudioPlayer _player;
  final AssetBundle _bundle;

  Future<Map<String, Object?>> _readManifest() async {
    final raw = await _bundle.loadString(manifestAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('The Kannada audio manifest is invalid.');
    }
    return Map<String, Object?>.from(decoded);
  }

  Future<bool> get isReady async {
    try {
      final manifest = await _readManifest();
      if (manifest['approval_status'] != 'approved' ||
          (manifest['approved_by']?.toString().trim().isEmpty ?? true) ||
          (manifest['approval_reference']?.toString().trim().isEmpty ?? true)) {
        return false;
      }
      final clips = manifest['clips'];
      if (clips is! Map || clips.isEmpty) return false;
      for (final value in clips.values) {
        if (value is! String || value.trim().isEmpty) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }


  Future<bool> hasWordRecording(String itemId) async {
    try {
      final manifest = await _readManifest();
      if (!_hasApproval(manifest)) return false;
      final clips = manifest['word_clips'];
      if (clips is! Map) return false;
      final assetPath = clips[itemId];
      if (assetPath is! String || assetPath.trim().isEmpty) return false;
      await _bundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Plays one approved, bundled stimulus recording for catalogue preview.
  ///
  /// This method is intentionally not called by scored assessment trials.
  Future<void> playWord(String itemId) async {
    final manifest = await _readManifest();
    if (!_hasApproval(manifest)) {
      throw StateError(
        'Approved Kannada word recordings have not been installed.',
      );
    }
    final clips = manifest['word_clips'];
    if (clips is! Map) {
      throw const FormatException('The Kannada word recording list is invalid.');
    }
    final assetPath = clips[itemId];
    if (assetPath is! String || assetPath.trim().isEmpty) {
      throw StateError('No approved recording exists for item ' + itemId + '.');
    }
    await _bundle.load(assetPath);
    await _player.play(AssetSource(assetPath));
  }

  bool _hasApproval(Map<String, Object?> manifest) =>
      manifest['approval_status'] == 'approved' &&
      manifest['word_audio_status'] == 'approved' &&
      (manifest['approved_by']?.toString().trim().isNotEmpty ?? false) &&
      (manifest['approval_reference']?.toString().trim().isNotEmpty ?? false);

  Future<void> play(String clipKey) async {
    final manifest = await _readManifest();
    if (manifest['approval_status'] != 'approved' ||
        (manifest['approved_by']?.toString().trim().isEmpty ?? true) ||
        (manifest['approval_reference']?.toString().trim().isEmpty ?? true)) {
      throw StateError(
        'Approved Kannada instruction recordings have not been installed.',
      );
    }
    final clips = manifest['clips'];
    if (clips is! Map) {
      throw const FormatException('The Kannada audio clip list is invalid.');
    }
    final assetPath = clips[clipKey];
    if (assetPath is! String || assetPath.trim().isEmpty) {
      throw StateError('The approved Kannada audio clip "' + clipKey + '" is missing.');
    }
    await _bundle.load(assetPath);
    await _player.play(AssetSource(assetPath));
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
