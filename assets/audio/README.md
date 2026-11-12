# Kannada audio package

PadLab uses locally bundled recordings only. Device text-to-speech and remote speech services are not substitutes for approved study recordings.

## Required instruction recordings

The manifest at `audio_manifest.json` requires these exact keys under `clips`:

- `assessor_welcome`
- `child_instructions`
- `practice_instructions`
- `completion_instruction`
- `reward_instruction`

Each key must point to a non-empty file under `assets/audio/`. The instruction batch must set `approval_status` to `approved` and include `approved_by` and `approval_reference`.

## Per-word recordings

Use one recording per stable item ID, for example:

- `assets/audio/words/W001.mp3`
- `assets/audio/words/W002.mp3`
- `assets/audio/words/W270.mp3`

The manifest must map each word ID in `word_clips`. Every mapped item also requires a non-empty reference under `word_audio_item_approvals`, plus the separate word-audio batch fields `word_audio_status`, `word_audio_approved_by` and `word_audio_approval_reference`.

A single audio path must not be reused for two different item IDs. Supported file extensions for the assessor's individual download action are `.mp3`, `.wav`, `.m4a`, `.ogg` and `.flac`.

## Review and verification

The Settings screen's Audio QA panel checks the five required instruction keys and the 270 supplied real-word IDs. It reports path coverage, actual non-empty bundled files, approval coverage, missing word IDs, unsafe paths and duplicate word-audio mappings.

That automated check verifies manifest and asset integrity only. It cannot judge pronunciation clarity, dialect, child comprehension or whether a clip corresponds to the correct Kannada lexical item. A native Kannada reviewer must listen to each clip against the exact item text and source metadata, record their review reference, and resolve every mismatch. A second reviewer should verify disputed or high-risk items.

After adding approved files and updating the manifest:

1. Run `flutter test` and the audio-service audit tests.
2. Open Settings and confirm the instruction and word coverage counts.
3. Play each approved clip from the reviewer controls and download representative clips.
4. Verify all files play on the target Android tablet with network access disabled.
5. Confirm checksums and the human review log in the institution's approved content package.

The supplied 12-minute source recording referenced in the manifest has not been reviewed or segmented into approved instruction clips. The repository currently contains no approved instruction or word audio files.

Keep scored visual stimuli silent unless the PI approves a protocol amendment that explicitly changes this.
