import Foundation

public struct CandidateExtractor: Sendable {
    public var hints: [String: [String]]
    public var misrecognitionDetector: any VoiceMisrecognitionDetector

    public init(
        hints: [String: [String]] = CandidateExtractor.defaultHints,
        misrecognitionDetector: any VoiceMisrecognitionDetector = RuleBasedVoiceMisrecognitionDetector()
    ) {
        self.hints = hints
        self.misrecognitionDetector = misrecognitionDetector
    }

    public func extract(from diff: PromptDiff, suggestedScope: DictionaryScope = .user) -> [CorrectionCandidate] {
        var candidates: [CorrectionCandidate] = []

        let inferredHints = Self.inferredDeveloperTermHints(from: diff.finalEditedText)
        let candidateHints = hints.merging(inferredHints) { existing, inferred in
            Array(Set(existing + inferred)).sorted()
        }
        for (canonical, spokenForms) in candidateHints {
            guard diff.finalEditedText.contains(canonical) else { continue }
            for spoken in spokenForms where diff.rawText.contains(spoken) {
                let dangerous = DangerousCommandPolicy.isDangerous(canonical)
                let evidence = misrecognitionDetector.evidence(
                    rawPhrase: spoken,
                    correctedPhrase: canonical,
                    diff: diff
                )
                candidates.append(
                    CorrectionCandidate(
                        rawPhrase: spoken,
                        correctedPhrase: canonical,
                        confidence: dangerous ? min(0.4, evidence.confidence) : evidence.confidence,
                        reason: evidence.reason,
                        suggestedScope: suggestedScope,
                        dangerous: dangerous,
                        autoApplyAllowed: !dangerous && suggestedScope != .session
                    )
                )
            }
        }

        return deduplicate(candidates)
    }

    private static func inferredDeveloperTermHints(from text: String) -> [String: [String]] {
        var inferred: [String: [String]] = [:]
        for term in DeveloperTermSpeechRules.extractTerms(from: text) {
            guard let spoken = DeveloperTermSpeechRules.spokenPhrase(for: term) else {
                continue
            }
            inferred[term, default: []].append(spoken)
        }
        return inferred
    }

    private func deduplicate(_ candidates: [CorrectionCandidate]) -> [CorrectionCandidate] {
        var seen = Set<String>()
        var result: [CorrectionCandidate] = []
        for candidate in candidates {
            let key = candidate.rawPhrase + "=>" + candidate.correctedPhrase
            if !seen.contains(key) {
                seen.insert(key)
                result.append(candidate)
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.confidence != rhs.confidence { return lhs.confidence > rhs.confidence }
            return lhs.correctedPhrase < rhs.correctedPhrase
        }
    }

    public static let defaultHints: [String: [String]] = [
        "Claude Code": ["クロードコード", "くらうどこーど", "くらのコード"],
        "Codex": ["こーでっくす", "コーデックス"],
        "TypeScript": ["タイプスクリプト", "たいぷすくりぷと"],
        "pnpm": ["ぴーえぬぴーえむ", "ピーエヌピーエム"],
        "MCP": ["えむしーぴー", "エムシーピー"],
        "branch": ["ブランチ"],
        "error": ["エラー"],
        "rm": ["アールエム"],
        "delete": ["削除"]
    ]
}
