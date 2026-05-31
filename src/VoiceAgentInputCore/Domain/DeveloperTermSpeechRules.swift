import Foundation

public enum DeveloperTermSpeechRules {
    public static func extractTerms(from text: String) -> [String] {
        var terms: [String] = []
        for phrase in ["Claude Code"] where text.localizedCaseInsensitiveContains(phrase) {
            terms.append(phrase)
        }

        let pattern = #"[A-Z]{2,}|[A-Z][A-Za-z0-9]*|[a-z]+(?:[A-Z][A-Za-z0-9]+)+|[a-z0-9]+(?:[-_][a-z0-9]+)+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return terms
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        terms += regex.matches(in: text, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: text) else {
                return nil
            }
            let term = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            return isUsefulTerm(term) ? term : nil
        }
        return terms
    }

    public static func spokenPhrase(for term: String) -> String? {
        let lower = term.lowercased()
        let fixed: [String: String] = [
            "api": "えーぴーあい",
            "json": "じぇいそん",
            "yaml": "やむる",
            "http": "えいちてぃーてぃーぴー",
            "https": "えいちてぃーてぃーぴーえす",
            "ui": "ゆーあい",
            "ux": "ゆーえっくす",
            "llm": "えるえるえむ",
            "stt": "えすてぃーてぃー",
            "mcp": "えむしーぴー",
            "cli": "しーえるあい",
            "ios": "あいおーえす",
            "macos": "まっくおーえす",
            "swiftui": "すいふとゆーあい",
            "typescript": "たいぷすくりぷと",
            "javascript": "じゃばすくりぷと",
            "github": "ぎっとはぶ",
            "codex": "こーでっくす",
            "claude code": "くろーどこーど",
            "cursor": "かーそる"
        ]
        if let phrase = fixed[lower] {
            return phrase
        }
        if term.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }), term.count <= 6, term.uppercased() == term {
            return term.lowercased().map(String.init).joined(separator: " ")
        }
        if let phrase = spokenIdentifierPhrase(for: term) {
            return phrase
        }
        return nil
    }

    private static func spokenIdentifierPhrase(for term: String) -> String? {
        let components = identifierComponents(for: term)
        guard components.count >= 2 else {
            return nil
        }
        guard components.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isASCII) }) else {
            return nil
        }
        return components.map { $0.lowercased() }.joined(separator: " ")
    }

    private static func identifierComponents(for term: String) -> [String] {
        if term.contains("_") || term.contains("-") {
            return term
                .split { $0 == "_" || $0 == "-" }
                .map(String.init)
                .filter { !$0.isEmpty }
        }

        var components: [String] = []
        var current = ""
        for character in term {
            if character.isUppercase, !current.isEmpty {
                components.append(current)
                current = String(character)
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty {
            components.append(current)
        }
        return components
    }

    private static func isUsefulTerm(_ term: String) -> Bool {
        guard term.count >= 2 else {
            return false
        }
        let ignored = Set([
            "I", "A", "The", "This", "That", "And", "But", "You", "User",
            "Assistant", "TODO", "OK", "Error"
        ])
        if ignored.contains(term) {
            return false
        }
        return term.contains { $0.isLetter }
    }
}
