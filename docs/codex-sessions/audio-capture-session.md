# Audio Capture Session

Purpose: improve microphone recording without changing speech recognition, normalization, preview, learning, or output.

Read:
- `docs/contracts/audio-capture.md`
- `src/VoiceAgentInputCore/App/AudioRecorder.swift`
- `src/VoiceAgentInputCore/App/RecordedAudio.swift`
- `src/VoiceAgentInputCore/Infra/AVFoundationAudioRecorder.swift`

May touch:
- Audio recorder adapters, temporary audio cleanup, and recording tests.

Avoid:
- Speech engines, dictionary correction, prompt refinement, preview UI, learning, output adapters.

Contract:
- Return `RecordedAudio` only.
- Do not transcribe, correct, refine, paste, learn, or persist raw audio by default.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputFlowRecordsAudioBeforeTranscriptionAndPreview`
- `swift test --filter UseCaseAndRepositoryTests/testTemporaryRecordedAudioFileStoreRemovesFileAfterSuccessfulOperation`
- `make check`

Done:
- Recording behavior remains local, temporary, and covered by tests.
