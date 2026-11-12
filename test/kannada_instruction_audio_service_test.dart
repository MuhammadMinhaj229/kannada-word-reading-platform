import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/audio/kannada_instruction_audio_service.dart';

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.manifest, this.availableAssets);

  final Map<String, Object?> manifest;
  final Set<String> availableAssets;

  @override
  Future<ByteData> load(String key) async {
    if (!availableAssets.contains(key)) {
      throw StateError('Asset not found: ' + key);
    }
    return ByteData.sublistView(Uint8List.fromList(<int>[1, 2, 3]));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key != KannadaInstructionAudioService.manifestAsset) {
      throw StateError('Unexpected manifest path: ' + key);
    }
    return jsonEncode(manifest);
  }
}

Map<String, Object?> _manifest({
  String approvalStatus = 'approved',
  String wordStatus = 'approved',
  String? wordApprovedBy = 'Kannada reviewer',
  String? wordApprovalReference = 'WORD-AUDIO-REVIEW-001',
  Map<String, Object?>? itemApprovals,
  Map<String, Object?>? instructionClips,
  Map<String, Object?>? wordClips,
}) {
  return <String, Object?>{
    'approval_status': approvalStatus,
    'approved_by': approvalStatus == 'approved' ? 'Instruction reviewer' : null,
    'approval_reference':
        approvalStatus == 'approved' ? 'INSTRUCTION-REVIEW-001' : null,
    'clips': instructionClips ?? <String, Object?>{
      'assessor_welcome': null,
      'child_instructions': null,
      'practice_instructions': null,
      'completion_instruction': null,
      'reward_instruction': null,
    },
    'word_audio_status': wordStatus,
    'word_audio_approved_by': wordApprovedBy,
    'word_audio_approval_reference': wordApprovalReference,
    'word_audio_item_approvals': itemApprovals ?? <String, Object?>{
      'W001': 'ITEM-REVIEW-W001',
    },
    'word_clips': wordClips ?? <String, Object?>{
      'W001': 'assets/audio/words/W001.mp3',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('instruction-audio approval cannot unlock word recordings', () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(wordStatus: 'pending_study_team_audio_approval'),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    );

    expect(await service.hasWordRecording('W001'), isFalse);
  });

  test('word audio requires its own batch approval reference', () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(wordApprovedBy: null, wordApprovalReference: null),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    );

    expect(await service.hasWordRecording('W001'), isFalse);
  });

  test('word audio requires a per-item review reference', () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(itemApprovals: <String, Object?>{}),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    );

    expect(await service.hasWordRecording('W001'), isFalse);
  });

  test('approved word playback requires an existing bundled asset', () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    );

    expect(await service.hasWordRecording('W001'), isTrue);
    expect(await service.hasWordRecording('W002'), isFalse);
  });

  test('instruction audit verifies all five approved bundled clips', () async {
    final clips = <String, Object?>{
      for (final key in KannadaInstructionAudioService.requiredInstructionClipKeys)
        key: 'assets/audio/instructions/' + key + '.mp3',
    };
    final bundle = _MemoryAssetBundle(
      _manifest(instructionClips: clips),
      clips.values.cast<String>().toSet(),
    );
    final report = await KannadaInstructionAudioService(bundle: bundle)
        .auditPackage();

    expect(report.instructionRequiredCount, 5);
    expect(report.instructionMappedCount, 5);
    expect(report.instructionAssetPresentCount, 5);
    expect(report.instructionApprovedAssetCount, 5);
    expect(report.instructionReady, isTrue);
  });

  test('instruction audit distinguishes present files from approval', () async {
    final clips = <String, Object?>{
      for (final key in KannadaInstructionAudioService.requiredInstructionClipKeys)
        key: 'assets/audio/instructions/' + key + '.mp3',
    };
    final bundle = _MemoryAssetBundle(
      _manifest(
        approvalStatus: 'pending_study_team_audio_approval',
        instructionClips: clips,
      ),
      clips.values.cast<String>().toSet(),
    );
    final report = await KannadaInstructionAudioService(bundle: bundle)
        .auditPackage();

    expect(report.instructionMappedCount, 5);
    expect(report.instructionAssetPresentCount, 5);
    expect(report.instructionApprovedAssetCount, 0);
    expect(report.instructionReady, isFalse);
    expect(report.instructionIssues, isNotEmpty);
  });

  test('word audit checks mapping, batch approval, item approval and file',
      () async {
    final report = await KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    ).auditPackage(wordItemIds: const <String>['W001', 'W002']);

    expect(report.wordRequiredCount, 2);
    expect(report.wordMappedCount, 1);
    expect(report.wordApprovedCount, 1);
    expect(report.wordAssetPresentCount, 1);
    expect(report.wordReadyCount, 1);
    expect(report.missingWordIds, <String>['W002']);
    expect(report.wordAudioReady, isFalse);
  });

  test('audio audit rejects paths outside bundled audio directory', () async {
    final manifest = _manifest(
      wordClips: <String, Object?>{
        'W001': 'assets/audio/../private/W001.mp3',
      },
    );
    final report = await KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        manifest,
        <String>{'assets/audio/../private/W001.mp3'},
      ),
    ).auditPackage(wordItemIds: const <String>['W001']);

    expect(report.wordMappedCount, 0);
    expect(report.wordReadyCount, 0);
    expect(report.missingWordIds, <String>['W001']);
  });
}
