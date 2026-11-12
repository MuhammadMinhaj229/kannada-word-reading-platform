import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';

/// Read-only integrity report for the bundled Kannada audio package.
class KannadaAudioPackageAudit {
  const KannadaAudioPackageAudit({
    required this.manifestReadable,
    required this.instructionRequiredCount,
    required this.instructionMappedCount,
    required this.instructionAssetPresentCount,
    required this.instructionApprovedAssetCount,
    required this.wordRequiredCount,
    required this.wordMappedCount,
    required this.wordApprovedCount,
    required this.wordAssetPresentCount,
    required this.wordReadyCount,
    required this.instructionIssues,
    required this.wordIssues,
    required this.missingWordIds,
  });

  final bool manifestReadable;
  final int instructionRequiredCount;
  final int instructionMappedCount;
  final int instructionAssetPresentCount;
  final int instructionApprovedAssetCount;
  final int wordRequiredCount;
  final int wordMappedCount;
  final int wordApprovedCount;
  final int wordAssetPresentCount;
  final int wordReadyCount;
  final List<String> instructionIssues;
  final List<String> wordIssues;
  final List<String> missingWordIds;

  bool get instructionReady =>
      manifestReadable &&
      instructionApprovedAssetCount == instructionRequiredCount;

  bool get wordAudioReady =>
      manifestReadable &&
      wordRequiredCount > 0 &&
      wordReadyCount == wordRequiredCount;

  bool get complete => instructionReady && wordAudioReady;
}

/// Plays only locally bundled recordings with documented study-team approval.
///
/// No text-to-speech or network speech fallback is provided. The service
/// separates instruction-package approval from per-word audio approval.
class KannadaInstructionAudioService {
  KannadaInstructionAudioService({
    AudioPlayer? player,
    AssetBundle? bundle,
  })  : _player = player,
        _bundle = bundle ?? rootBundle;

  static const String manifestAsset = 'assets/audio/audio_manifest.json';

  static const List<String> requiredInstructionClipKeys = <String>[
    'assessor_welcome',
    'child_instructions',
    'practice_instructions',
    'completion_instruction',
    'reward_instruction',
  ];

  AudioPlayer? _player;

  AudioPlayer get _audioPlayer => _player ??= AudioPlayer();
  final AssetBundle _bundle;

  Future<Map<String, Object?>> _readManifest() async {
    final raw = await _bundle.loadString(manifestAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('The Kannada audio manifest is invalid.');
    }
    return Map<String, Object?>.from(decoded);
  }

  bool _hasApproval(
    Map<String, Object?> manifest, {
    required String statusKey,
    required String approverKey,
    required String referenceKey,
  }) {
    return manifest[statusKey] == 'approved' &&
        (manifest[approverKey]?.toString().trim().isNotEmpty ?? false) &&
        (manifest[referenceKey]?.toString().trim().isNotEmpty ?? false);
  }

  bool _isSafeAssetPath(String value) {
    return value.startsWith('assets/audio/') &&
        !value.contains('..') &&
        !value.contains('\\') &&
        !value.contains('\u0000');
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      final bytes = await _bundle.load(assetPath);
      return bytes.lengthInBytes > 0;
    } catch (_) {
      return false;
    }
  }

  /// Checks every required instruction key and every supplied word ID.
  ///
  /// Asset existence is checked independently from approval so reviewers can
  /// distinguish "file is present" from "file is authorised for use".
  Future<KannadaAudioPackageAudit> auditPackage({
    Iterable<String> wordItemIds = const <String>[],
  }) async {
    final ids = wordItemIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList()
      ..sort();
    final instructionIssues = <String>[];
    final wordIssues = <String>[];
    final missingWordIds = <String>[];

    Map<String, Object?> manifest;
    try {
      manifest = await _readManifest();
    } catch (error) {
      return KannadaAudioPackageAudit(
        manifestReadable: false,
        instructionRequiredCount: requiredInstructionClipKeys.length,
        instructionMappedCount: 0,
        instructionAssetPresentCount: 0,
        instructionApprovedAssetCount: 0,
        wordRequiredCount: ids.length,
        wordMappedCount: 0,
        wordApprovedCount: 0,
        wordAssetPresentCount: 0,
        wordReadyCount: 0,
        instructionIssues: <String>['Audio manifest could not be read: $error'],
        wordIssues: const <String>[],
        missingWordIds: List<String>.unmodifiable(ids),
      );
    }

    final instructionBatchApproved = _hasApproval(
      manifest,
      statusKey: 'approval_status',
      approverKey: 'approved_by',
      referenceKey: 'approval_reference',
    );
    if (!instructionBatchApproved) {
      instructionIssues.add(
        'Instruction batch approval, approver or approval reference is missing.',
      );
    }

    final rawInstructionClips = manifest['clips'];
    final instructionClips =
        rawInstructionClips is Map ? rawInstructionClips : const <Object?, Object?>{};
    var instructionMapped = 0;
    var instructionAssetsPresent = 0;
    var instructionApprovedAssets = 0;

    for (final key in requiredInstructionClipKeys) {
      final value = instructionClips[key];
      if (value is! String || value.trim().isEmpty) {
        instructionIssues.add('$key: required clip path is missing.');
        continue;
      }
      final assetPath = value.trim();
      if (!_isSafeAssetPath(assetPath)) {
        instructionIssues.add('$key: clip path is outside assets/audio/.');
        continue;
      }
      instructionMapped += 1;
      if (!await _assetExists(assetPath)) {
        instructionIssues.add('$key: bundled asset is missing or empty ($assetPath).');
        continue;
      }
      instructionAssetsPresent += 1;
      if (instructionBatchApproved) instructionApprovedAssets += 1;
    }

    final wordBatchApproved = _hasApproval(
      manifest,
      statusKey: 'word_audio_status',
      approverKey: 'word_audio_approved_by',
      referenceKey: 'word_audio_approval_reference',
    );
    if (!wordBatchApproved && ids.isNotEmpty) {
      wordIssues.add(
        'Word-audio batch approval, approver or approval reference is missing.',
      );
    }

    final rawWordClips = manifest['word_clips'];
    final wordClips = rawWordClips is Map ? rawWordClips : const <Object?, Object?>{};
    final rawItemApprovals = manifest['word_audio_item_approvals'];
    final itemApprovals =
        rawItemApprovals is Map ? rawItemApprovals : const <Object?, Object?>{};
    var wordMapped = 0;
    var wordApproved = 0;
    var wordAssetsPresent = 0;
    var wordReady = 0;
    final pathOwners = <String, String>{};

    for (final id in ids) {
      final value = wordClips[id];
      if (value is! String || value.trim().isEmpty) {
        missingWordIds.add(id);
        wordIssues.add('$id: recording path is missing.');
        continue;
      }
      final assetPath = value.trim();
      if (!_isSafeAssetPath(assetPath)) {
        missingWordIds.add(id);
        wordIssues.add('$id: recording path is outside assets/audio/.');
        continue;
      }
      wordMapped += 1;
      final previousOwner = pathOwners[assetPath];
      var uniqueItemPath = true;
      if (previousOwner != null && previousOwner != id) {
        uniqueItemPath = false;
        wordIssues.add('$id: recording path is also assigned to $previousOwner.');
      } else {
        pathOwners[assetPath] = id;
      }

      final itemApproved =
          itemApprovals[id]?.toString().trim().isNotEmpty ?? false;
      final approved = wordBatchApproved && itemApproved;
      if (approved) wordApproved += 1;
      if (!itemApproved) {
        wordIssues.add('$id: per-item linguistic/audio approval reference is missing.');
      }

      if (!await _assetExists(assetPath)) {
        missingWordIds.add(id);
        wordIssues.add('$id: bundled recording is missing or empty ($assetPath).');
        continue;
      }
      wordAssetsPresent += 1;
      if (approved && uniqueItemPath) wordReady += 1;
    }

    return KannadaAudioPackageAudit(
      manifestReadable: true,
      instructionRequiredCount: requiredInstructionClipKeys.length,
      instructionMappedCount: instructionMapped,
      instructionAssetPresentCount: instructionAssetsPresent,
      instructionApprovedAssetCount: instructionApprovedAssets,
      wordRequiredCount: ids.length,
      wordMappedCount: wordMapped,
      wordApprovedCount: wordApproved,
      wordAssetPresentCount: wordAssetsPresent,
      wordReadyCount: wordReady,
      instructionIssues: List<String>.unmodifiable(instructionIssues),
      wordIssues: List<String>.unmodifiable(wordIssues),
      missingWordIds: List<String>.unmodifiable(missingWordIds),
    );
  }

  /// Instruction readiness intentionally does not imply word-audio readiness.
  Future<bool> get isReady async {
    final report = await auditPackage();
    return report.instructionReady;
  }

  Future<bool> hasWordRecording(String itemId) async {
    try {
      final manifest = await _readManifest();
      final assetPath = _approvedWordAsset(manifest, itemId);
      if (assetPath == null) return false;
      return await _assetExists(assetPath);
    } catch (_) {
      return false;
    }
  }

  /// Plays one approved, bundled stimulus recording for catalogue preview.
  ///
  /// This method is intentionally not called by scored assessment trials.
  Future<void> playWord(String itemId) async {
    final manifest = await _readManifest();
    final assetPath = _approvedWordAsset(manifest, itemId);
    if (assetPath == null) {
      throw StateError(
        'This item has no recording with explicit word-audio and item-level approval.',
      );
    }
    if (!await _assetExists(assetPath)) {
      throw StateError('The approved recording for $itemId is missing or empty.');
    }
    await _audioPlayer.play(AssetSource(assetPath));
  }

  /// Downloads an individual recording only after batch and item approval.
  Future<void> downloadWord(String itemId) async {
    final manifest = await _readManifest();
    final assetPath = _approvedWordAsset(manifest, itemId);
    if (assetPath == null) {
      throw StateError(
        'This item has no recording with explicit word-audio and item-level approval.',
      );
    }
    final bytes = await _bundle.load(assetPath);
    if (bytes.lengthInBytes == 0) {
      throw StateError('The approved recording for $itemId is empty.');
    }
    final extension = assetPath.split('.').last.toLowerCase();
    const supportedExtensions = <String>{'mp3', 'wav', 'm4a', 'ogg', 'flac'};
    if (!supportedExtensions.contains(extension)) {
      throw StateError('Unsupported approved audio format: $extension.');
    }
    final audioBytes = Uint8List.fromList(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    await FileSaver.instance.saveAs(
      name: 'padalab-$itemId',
      bytes: audioBytes,
      fileExtension: extension,
      mimeType: MimeType.other,
    );
  }

  String? _approvedWordAsset(
    Map<String, Object?> manifest,
    String itemId,
  ) {
    if (!_hasApproval(
      manifest,
      statusKey: 'word_audio_status',
      approverKey: 'word_audio_approved_by',
      referenceKey: 'word_audio_approval_reference',
    )) {
      return null;
    }
    final approvals = manifest['word_audio_item_approvals'];
    if (approvals is! Map ||
        (approvals[itemId]?.toString().trim().isEmpty ?? true)) {
      return null;
    }
    final clips = manifest['word_clips'];
    if (clips is! Map) return null;
    final assetPath = clips[itemId];
    if (assetPath is! String ||
        assetPath.trim().isEmpty ||
        !_isSafeAssetPath(assetPath.trim())) {
      return null;
    }
    return assetPath.trim();
  }

  Future<void> play(String clipKey) async {
    if (!requiredInstructionClipKeys.contains(clipKey)) {
      throw ArgumentError.value(clipKey, 'clipKey', 'Unknown instruction clip.');
    }
    final manifest = await _readManifest();
    if (!_hasApproval(
      manifest,
      statusKey: 'approval_status',
      approverKey: 'approved_by',
      referenceKey: 'approval_reference',
    )) {
      throw StateError(
        'Approved Kannada instruction recordings have not been installed.',
      );
    }
    final clips = manifest['clips'];
    if (clips is! Map) {
      throw const FormatException('The Kannada audio clip list is invalid.');
    }
    final value = clips[clipKey];
    if (value is! String ||
        value.trim().isEmpty ||
        !_isSafeAssetPath(value.trim())) {
      throw StateError('The approved Kannada instruction clip "$clipKey" is missing.');
    }
    final assetPath = value.trim();
    if (!await _assetExists(assetPath)) {
      throw StateError('The approved Kannada instruction clip "$clipKey" is missing or empty.');
    }
    await _audioPlayer.play(AssetSource(assetPath));
  }

  Future<void> stop() async {
    final player = _player;
    if (player != null) await player.stop();
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    if (player != null) await player.dispose();
  }
}
