import Foundation

public struct NormalizationEngine: Sendable {
    public var entries: [DictionaryEntry]

    public init(entries: [DictionaryEntry]) {
        self.entries = entries
    }

    public func normalize(_ rawText: String) -> NormalizationResult {
        var text = cleanup(rawText)
        var corrections: [AppliedCorrection] = []

        let orderedEntries = entries
            .filter { $0.autoApply }
            .sorted { lhs, rhs in
                if lhs.scope != rhs.scope { return lhs.scope > rhs.scope }
                if lhs.confidence != rhs.confidence { return lhs.confidence > rhs.confidence }
                return lhs.canonical.count > rhs.canonical.count
            }

        for entry in orderedEntries {
            let forms = entry.spokenForms.sorted { $0.count > $1.count }
            for form in forms where !form.isEmpty {
                var searchStart = text.startIndex
                while searchStart < text.endIndex,
                      let range = text.range(of: form, options: [], range: searchStart..<text.endIndex) {
                    let replacement = spacedReplacement(for: entry.canonical, in: text, replacing: range)
                    text.replaceSubrange(range, with: replacement)
                    corrections.append(
                        AppliedCorrection(
                            original: form,
                            replacement: replacement,
                            canonical: entry.canonical,
                            entryID: entry.id,
                            kind: entry.kind,
                            scope: entry.scope
                        )
                    )
                    searchStart = text.index(range.lowerBound, offsetBy: replacement.count, limitedBy: text.endIndex) ?? text.endIndex
                }
            }
        }

        return NormalizationResult(rawText: rawText, correctedText: cleanupSpacing(text), corrections: corrections)
    }

    private func cleanup(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{3000}", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanupSpacing(_ text: String) -> String {
        var current = text
        while current.contains("  ") {
            current = current.replacingOccurrences(of: "  ", with: " ")
        }
        return current.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func spacedReplacement(for canonical: String, in text: String, replacing range: Range<String.Index>) -> String {
        guard shouldSpace(canonical) else { return canonical }

        var replacement = canonical
        if range.lowerBound > text.startIndex {
            let before = text[text.index(before: range.lowerBound)]
            if !before.isWhitespaceLike && !before.isOpeningPunctuation {
                replacement = " " + replacement
            }
        }
        if range.upperBound < text.endIndex {
            let after = text[range.upperBound]
            if !after.isWhitespaceLike && !after.isClosingPunctuation {
                replacement += " "
            }
        }
        return replacement
    }

    private func shouldSpace(_ canonical: String) -> Bool {
        canonical.unicodeScalars.contains { scalar in
            (65...90).contains(Int(scalar.value)) ||
            (97...122).contains(Int(scalar.value)) ||
            (48...57).contains(Int(scalar.value))
        }
    }
}

private extension Character {
    var isWhitespaceLike: Bool {
        unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
    }

    var isOpeningPunctuation: Bool {
        ["(", "[", "{", "\"", "'"].contains(String(self))
    }

    var isClosingPunctuation: Bool {
        [")", "]", "}", ".", ",", ":", ";", "!", "?", "\"", "'"].contains(String(self))
    }
}
