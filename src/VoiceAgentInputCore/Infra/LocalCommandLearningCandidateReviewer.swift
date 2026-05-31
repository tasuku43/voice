import Foundation

public struct LocalCommandLearningReviewRequest: Codable, Equatable, Sendable {
    public var candidates: [CorrectionCandidate]
    public var diff: PromptDiff

    public init(candidates: [CorrectionCandidate], diff: PromptDiff) {
        self.candidates = candidates
        self.diff = diff
    }
}

public struct LocalCommandLearningReviewResponse: Codable, Equatable, Sendable {
    public var candidates: [CorrectionCandidate]

    public init(candidates: [CorrectionCandidate]) {
        self.candidates = candidates
    }
}

public enum LocalCommandLearningCandidateReviewerError: Error, Equatable {
    case commandNotConfigured
    case commandFailed(status: Int32, stderr: String)
    case timedOut(seconds: TimeInterval)
}

public struct LocalCommandLearningCandidateReviewer: LearningCandidateReviewer, Sendable {
    public var executableURL: URL?
    public var arguments: [String]
    public var timeoutSeconds: TimeInterval

    public init(
        executableURL: URL?,
        arguments: [String] = [],
        timeoutSeconds: TimeInterval = 2
    ) {
        self.executableURL = executableURL
        self.arguments = arguments
        self.timeoutSeconds = timeoutSeconds
    }

    public func review(candidates: [CorrectionCandidate], diff: PromptDiff) async throws -> [CorrectionCandidate] {
        guard let executableURL else {
            return candidates
        }

        let request = LocalCommandLearningReviewRequest(candidates: candidates, diff: diff)
        let input = try JSONEncoder().encode(request)
        let output = try await run(input: input, executableURL: executableURL)
        let response = try JSONDecoder().decode(LocalCommandLearningReviewResponse.self, from: output)
        return response.candidates.map(Self.preserveGuardrails(reviewed:originals:), originals: candidates)
    }

    private func run(input: Data, executableURL: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments

            let stdin = Pipe()
            let stdout = Pipe()
            let stderr = Pipe()
            process.standardInput = stdin
            process.standardOutput = stdout
            process.standardError = stderr

            let box = LocalCommandReviewContinuationBox(continuation: continuation)

            process.terminationHandler = { process in
                let output = stdout.fileHandleForReading.readDataToEndOfFile()
                let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                if process.terminationStatus == 0 {
                    box.finish(.success(output))
                } else {
                    let errorText = String(data: errorData, encoding: .utf8) ?? ""
                    box.finish(.failure(LocalCommandLearningCandidateReviewerError.commandFailed(
                        status: process.terminationStatus,
                        stderr: errorText
                    )))
                }
            }

            do {
                try process.run()
                stdin.fileHandleForWriting.write(input)
                try stdin.fileHandleForWriting.close()
            } catch {
                box.finish(.failure(error))
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds) {
                if !box.isCompleted {
                    box.finish(.failure(LocalCommandLearningCandidateReviewerError.timedOut(seconds: timeoutSeconds)))
                    process.terminate()
                }
            }
        }
    }

    private static func preserveGuardrails(
        reviewed: CorrectionCandidate,
        originals: [CorrectionCandidate]
    ) -> CorrectionCandidate {
        guard let original = originals.first(where: {
            $0.rawPhrase == reviewed.rawPhrase &&
                $0.correctedPhrase == reviewed.correctedPhrase &&
                $0.suggestedScope == reviewed.suggestedScope
        }) else {
            var safe = reviewed
            safe.autoApplyAllowed = false
            return safe
        }

        var safe = reviewed
        safe.dangerous = original.dangerous || reviewed.dangerous
        safe.autoApplyAllowed = original.autoApplyAllowed && reviewed.autoApplyAllowed && !safe.dangerous
        if safe.dangerous {
            safe.confidence = min(0.4, safe.confidence)
        }
        return safe
    }
}

private final class LocalCommandReviewContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var completed = false
    private let continuation: CheckedContinuation<Data, Error>

    init(continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    var isCompleted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return completed
    }

    func finish(_ result: Result<Data, Error>) {
        lock.lock()
        guard !completed else {
            lock.unlock()
            return
        }
        completed = true
        lock.unlock()
        continuation.resume(with: result)
    }
}

private extension Array where Element == CorrectionCandidate {
    func map(
        _ transform: (CorrectionCandidate, [CorrectionCandidate]) -> CorrectionCandidate,
        originals: [CorrectionCandidate]
    ) -> [CorrectionCandidate] {
        map { transform($0, originals) }
    }
}
