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
      throw FlutterError('Asset not found: ' + key);
    }
    return ByteData.sublistView(Uint8List.fromList(<int>[1, 2, 3]));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key != KannadaInstructionAudioService.manifestAsset) {
      throw FlutterError('Unexpected manifest path: ' + key);
    }
    return jsonEncode(manifest);
  }
}

Map<String, Object?> _manifest({
  String wordStatus = 'approved',
  String? wordApprovedBy = 'Kannada reviewer',
  String? wordApprovalReference = 'WORD-AUDIO-REVIEW-001',
  Map<String, Object?>? itemApprovals,
}) {
  return <String, Object?>{
    'approval_status': 'approved',
    'approved_by': 'Instruction reviewer',
    'approval_reference': 'INSTRUCTION-REVIEW-001',
    'word_audio_status': wordStatus,
    'word_audio_approved_by': wordApprovedBy,
    'word_audio_approval_reference': wordApprovalReference,
    'word_audio_item_approvals': itemApprovals ?? <String, Object?>{
      'W001': 'ITEM-REVIEW-W001',
    },
    'word_clips': <String, Object?>{
      'W001': 'assets/audio/words/W001.mp3',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('instruction-audio approval cannot unlock word recordings', () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(
          wordStatus: 'pending_study_team_audio_approval',
        ),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    );

    expect(await service.hasWordRecording('W001'), isFalse);
  });

  test('word audio requires its own batch approval reference', () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(
          wordApprovedBy: null,
          wordApprovalReference: null,
        ),
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

  test('exposes playback only for an approved item with a bundled asset',
      () async {
    final service = KannadaInstructionAudioService(
      bundle: _MemoryAssetBundle(
        _manifest(),
        <String>{'assets/audio/words/W001.mp3'},
      ),
    );

    expect(await service.hasWordRecording('W001'), isTrue);
    expect(await service.hasWordRecording('W002'), isFalse);
  });
}
