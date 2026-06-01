# Audio Capture Contract

## Inputs
- Recording settings such as temporary directory.
- A recording start request from the app or pipeline, including press-and-hold or toggle hotkey flows.
- A user stop request.

## Outputs
- `RecordedAudio`
- Audio bytes, format description, and duration.

## Allowed
- Capture one microphone recording.
- Keep recording until the user explicitly stops by key release, toggle press, or Stop action.
- Expose microphone input level for recording feedback.
- Use a temporary file while recording.
- Remove temporary audio after reading it.

## Forbidden
- Speech recognition.
- Dictionary correction.
- Prompt refinement.
- Preview, paste, or learning.
- Persist raw audio by default.

## Read First
- `src/VoiceAgentInputCore/App/AudioRecorder.swift`
- `src/VoiceAgentInputCore/App/RecordedAudio.swift`
- `src/VoiceAgentInputCore/Infra/AVFoundationAudioRecorder.swift`

## May Touch
- Audio recorder protocols, temporary audio handling, and recorder tests.

## Avoid Touching
- Speech, normalization, preview, learning, and output logic.

## Tests
- `swift test --filter UseCaseAndRepositoryTests/testVoiceInputFlowRecordsAudioBeforeTranscriptionAndPreview`
- `swift test --filter UseCaseAndRepositoryTests/testTemporaryRecordedAudioFileStoreRemovesFileAfterSuccessfulOperation`
- `make check`

## Done
- Audio capture returns `RecordedAudio` only.
- Recording ends by user stop instead of a short fixed timer.
- Hotkey trigger behavior can be press-and-hold or toggle without changing the audio recorder contract.
- UI can distinguish microphone connection wait from active input.
- Temporary raw audio is removed and not persisted by default.
