import Foundation

public struct TranscriptionQualityEvaluation: Codable, Equatable, Sendable {
    public var expectedCharacterCount: Int
    public var actualCharacterCount: Int
    public var editDistance: Int
    public var characterErrorRate: Double
    public var expectedContentCharacterCount: Int
    public var actualContentCharacterCount: Int
    public var contentEditDistance: Int
    public var contentCharacterErrorRate: Double
    public var expectedPunctuationCount: Int
    public var actualPunctuationCount: Int
    public var punctuationEditDistance: Int
    public var punctuationErrorRate: Double
    public var expectedLineBreakCount: Int
    public var actualLineBreakCount: Int
    public var lineBreakEditDistance: Int
    public var lineBreakErrorRate: Double

    public init(
        expectedCharacterCount: Int,
        actualCharacterCount: Int,
        editDistance: Int,
        characterErrorRate: Double,
        expectedContentCharacterCount: Int,
        actualContentCharacterCount: Int,
        contentEditDistance: Int,
        contentCharacterErrorRate: Double,
        expectedPunctuationCount: Int,
        actualPunctuationCount: Int,
        punctuationEditDistance: Int,
        punctuationErrorRate: Double,
        expectedLineBreakCount: Int,
        actualLineBreakCount: Int,
        lineBreakEditDistance: Int,
        lineBreakErrorRate: Double
    ) {
        self.expectedCharacterCount = expectedCharacterCount
        self.actualCharacterCount = actualCharacterCount
        self.editDistance = editDistance
        self.characterErrorRate = characterErrorRate
        self.expectedContentCharacterCount = expectedContentCharacterCount
        self.actualContentCharacterCount = actualContentCharacterCount
        self.contentEditDistance = contentEditDistance
        self.contentCharacterErrorRate = contentCharacterErrorRate
        self.expectedPunctuationCount = expectedPunctuationCount
        self.actualPunctuationCount = actualPunctuationCount
        self.punctuationEditDistance = punctuationEditDistance
        self.punctuationErrorRate = punctuationErrorRate
        self.expectedLineBreakCount = expectedLineBreakCount
        self.actualLineBreakCount = actualLineBreakCount
        self.lineBreakEditDistance = lineBreakEditDistance
        self.lineBreakErrorRate = lineBreakErrorRate
    }

    public static func evaluate(
        actual: String,
        expected: String
    ) -> TranscriptionQualityEvaluation {
        let actualCharacters = normalizedCharacters(actual)
        let expectedCharacters = normalizedCharacters(expected)
        let distance = editDistance(actualCharacters, expectedCharacters)
        let actualContent = contentCharacters(actual)
        let expectedContent = contentCharacters(expected)
        let contentDistance = editDistance(actualContent, expectedContent)
        let actualPunctuation = punctuationCharacters(actual)
        let expectedPunctuation = punctuationCharacters(expected)
        let punctuationDistance = editDistance(actualPunctuation, expectedPunctuation)
        let actualLineBreaks = lineBreakCharacters(actual)
        let expectedLineBreaks = lineBreakCharacters(expected)
        let lineBreakDistance = editDistance(actualLineBreaks, expectedLineBreaks)

        return TranscriptionQualityEvaluation(
            expectedCharacterCount: expectedCharacters.count,
            actualCharacterCount: actualCharacters.count,
            editDistance: distance,
            characterErrorRate: rate(distance: distance, expectedCount: expectedCharacters.count),
            expectedContentCharacterCount: expectedContent.count,
            actualContentCharacterCount: actualContent.count,
            contentEditDistance: contentDistance,
            contentCharacterErrorRate: rate(distance: contentDistance, expectedCount: expectedContent.count),
            expectedPunctuationCount: expectedPunctuation.count,
            actualPunctuationCount: actualPunctuation.count,
            punctuationEditDistance: punctuationDistance,
            punctuationErrorRate: rate(distance: punctuationDistance, expectedCount: expectedPunctuation.count),
            expectedLineBreakCount: expectedLineBreaks.count,
            actualLineBreakCount: actualLineBreaks.count,
            lineBreakEditDistance: lineBreakDistance,
            lineBreakErrorRate: rate(distance: lineBreakDistance, expectedCount: expectedLineBreaks.count)
        )
    }

    private static func normalizedCharacters(_ text: String) -> [Character] {
        let folded = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        let normalized = folded
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "、", with: ",")
            .replacingOccurrences(of: "。", with: ".")
            .replacingOccurrences(of: "､", with: ",")
            .replacingOccurrences(of: "｡", with: ".")
            .lowercased()

        var characters: [Character] = []
        var previousWasWhitespace = false
        for character in normalized {
            if character.isWhitespace {
                if !previousWasWhitespace {
                    characters.append(" ")
                    previousWasWhitespace = true
                }
            } else {
                characters.append(character)
                previousWasWhitespace = false
            }
        }
        if characters.first == " " {
            characters.removeFirst()
        }
        if characters.last == " " {
            characters.removeLast()
        }
        return characters
    }

    private static func contentCharacters(_ text: String) -> [Character] {
        canonicalizedText(text).filter { character in
            !character.isWhitespace && !isPunctuation(character)
        }
    }

    private static func punctuationCharacters(_ text: String) -> [Character] {
        canonicalizedText(text).filter { isPunctuation($0) }
    }

    private static func lineBreakCharacters(_ text: String) -> [Character] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .filter { $0 == "\n" }
    }

    private static func canonicalizedText(_ text: String) -> [Character] {
        let folded = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return folded
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "、", with: ",")
            .replacingOccurrences(of: "。", with: ".")
            .replacingOccurrences(of: "､", with: ",")
            .replacingOccurrences(of: "｡", with: ".")
            .lowercased()
            .map { $0 }
    }

    private static func isPunctuation(_ character: Character) -> Bool {
        [",", ".", "!", "?", ":", ";", "、", "。", "，", "．", "､", "｡"].contains(character)
    }

    private static func rate(distance: Int, expectedCount: Int) -> Double {
        Double(distance) / Double(max(expectedCount, 1))
    }

    private static func editDistance(_ lhs: [Character], _ rhs: [Character]) -> Int {
        guard !lhs.isEmpty else {
            return rhs.count
        }
        guard !rhs.isEmpty else {
            return lhs.count
        }

        var previous = Array(0...rhs.count)
        var current = Array(repeating: 0, count: rhs.count + 1)

        for lhsIndex in 1...lhs.count {
            current[0] = lhsIndex
            for rhsIndex in 1...rhs.count {
                let substitutionCost = lhs[lhsIndex - 1] == rhs[rhsIndex - 1] ? 0 : 1
                current[rhsIndex] = min(
                    previous[rhsIndex] + 1,
                    current[rhsIndex - 1] + 1,
                    previous[rhsIndex - 1] + substitutionCost
                )
            }
            swap(&previous, &current)
        }

        return previous[rhs.count]
    }
}
