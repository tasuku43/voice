import AVFoundation
import Foundation

public final class AVFoundationAudioRecorder: NSObject, AudioRecorder, AVAudioRecorderDelegate, @unchecked Sendable {
    public let temporaryDirectory: URL

    private var recordingStartDate: Date?
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var continuation: CheckedContinuation<RecordedAudio, Error>?

    public init(temporaryDirectory: URL = FileManager.default.temporaryDirectory) {
        self.temporaryDirectory = temporaryDirectory
    }

    public func recordOnce() async throws -> RecordedAudio {
        guard continuation == nil else {
            throw AVFoundationAudioRecorderError.recordingAlreadyInProgress
        }

        let url = temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = false
        recorder.prepareToRecord()
        self.recorder = recorder
        recordingStartDate = Date()

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            if recorder.record() == false {
                finishWithError(AVFoundationAudioRecorderError.failedToStartRecording)
            }
        }
    }

    public func stopRecording() {
        recorder?.stop()
    }

    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            finishSuccessfully()
        } else {
            finishWithError(AVFoundationAudioRecorderError.recordingFailed)
        }
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        finishWithError(error ?? AVFoundationAudioRecorderError.recordingFailed)
    }

    private func finishSuccessfully() {
        guard let recordingURL else {
            finishWithError(AVFoundationAudioRecorderError.missingRecordingFile)
            return
        }

        do {
            let data = try Data(contentsOf: recordingURL)
            let audio = RecordedAudio(
                data: data,
                formatDescription: "caf/aac; sampleRate=16000; channels=1",
                durationSeconds: recordingStartDate.map { Date().timeIntervalSince($0) } ?? 0
            )
            cleanup()
            continuation?.resume(returning: audio)
            continuation = nil
        } catch {
            finishWithError(error)
        }
    }

    private func finishWithError(_ error: Error) {
        cleanup()
        continuation?.resume(throwing: error)
        continuation = nil
    }

    private func cleanup() {
        recorder?.stop()
        recorder = nil
        recordingStartDate = nil
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
    }
}

public enum AVFoundationAudioRecorderError: Error, Equatable {
    case recordingAlreadyInProgress
    case failedToStartRecording
    case recordingFailed
    case missingRecordingFile
}
