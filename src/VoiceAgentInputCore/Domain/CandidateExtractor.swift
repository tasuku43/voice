import Foundation

public struct CandidateExtractor: Sendable {
    public var hints: [String: [String]]

    public init(hints: [String: [String]] = CandidateExtractor.defaultHints) {
        self.hints = hints
    }

    public func extract(from diff: PromptDiff, suggestedScope: DictionaryScope = .user) -> [CorrectionCandidate] {
        var candidates: [CorrectionCandidate] = []

        for (canonical, spokenForms) in hints {
            guard diff.finalEditedText.contains(canonical) else { continue }
            for spoken in spokenForms where diff.rawText.contains(spoken) {
                let dangerous = DangerousCommandPolicy.isDangerous(canonical)
                candidates.append(
                    CorrectionCandidate(
                        rawPhrase: spoken,
                        correctedPhrase: canonical,
                        confidence: dangerous ? 0.4 : 0.72,
                        suggestedScope: suggestedScope,
                        dangerous: dangerous,
                        autoApplyAllowed: !dangerous && suggestedScope != .session
                    )
                )
            }
        }

        return deduplicate(candidates)
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
