# Audio Capture Session

Purpose: improve microphone recording without changing speech recognition, normalization, learning, or output.

Read:
- `docs/contracts/audio-capture.md`
- `src/VoiceAgentInputCore/App/AudioRecorder.swift`
- `src/VoiceAgentInputCore/App/RecordedAudio.swift`
- `src/VoiceAgentInputCore/Infra/AVFoundationAudioRecorder.swift`

May touch:
- Audio recorder adapters, temporary audio cleanup, and recording tests.

Avoid:
- Speech engines, dictionary correction, learning, and output adapters.

Contract:
- Return `RecordedAudio` only.
- End recording by explicit user stop.
- Expose input level for feedback without persisting audio.
- Do not transcribe, correct, refine, paste, learn, or persist raw audio by default.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputPipelineRecordsAudioBeforeTranscriptionAndProcessing`
- `swift test --filter UseCaseAndRepositoryTests/testTemporaryRecordedAudioFileStoreRemovesFileAfterSuccessfulOperation`
- `make check`

Done:
- Recording behavior remains local, temporary, and covered by tests.
