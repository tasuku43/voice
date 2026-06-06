import Foundation

public struct PromptTextRefinementRequest: Equatable, Sendable {
    public var transcript: Transcript
    public var normalizedText: String

    public init(transcript: Transcript, normalizedText: String) {
        self.transcript = transcript
        self.normalizedText = normalizedText
    }
}

public struct PromptTextRefinementResult: Codable, Equatable, Sendable {
    public var inputText: String
    public var refinedText: String
    public var engine: String

    public init(inputText: String, refinedText: String, engine: String) {
        self.inputText = inputText
        self.refinedText = refinedText
        self.engine = engine
    }
}

public protocol PromptTextRefiner: Sendable {
    func refine(_ request: PromptTextRefinementRequest) async throws -> PromptTextRefinementResult
}

public struct PromptTextRefinerChain: PromptTextRefiner {
    public var refiners: [any PromptTextRefiner]

    public init(refiners: [any PromptTextRefiner]) {
        self.refiners = refiners
    }

    public func refine(_ request: PromptTextRefinementRequest) async throws -> PromptTextRefinementResult {
        var currentText = request.normalizedText
        var engines: [String] = []

        for refiner in refiners {
            let result = try await refiner.refine(
                PromptTextRefinementRequest(
                    transcript: request.transcript,
                    normalizedText: currentText
                )
            )
            currentText = result.refinedText
            engines.append(result.engine)
        }

        return PromptTextRefinementResult(
            inputText: request.normalizedText,
            refinedText: currentText,
            engine: engines.joined(separator: "+")
        )
    }
}

public struct JapanesePauseSmoothingRefiner: PromptTextRefiner {
    public init() {}

    public func refine(_ request: PromptTextRefinementRequest) async throws -> PromptTextRefinementResult {
        PromptTextRefinementResult(
            inputText: request.normalizedText,
            refinedText: Self.smooth(request.normalizedText),
            engine: "JapanesePauseSmoothingRefiner"
        )
    }

    public static func smooth(_ text: String) -> String {
        var current = text
        let replacements = [
            ("特にまだ", "特に、まだ"),
            ("ついて僕", "ついて、僕"),
            ("として綺麗", "として、綺麗"),
            ("全員が例えば", "全員が、例えば"),
            ("できるようにかつ", "できるように、かつ"),
            ("そうすると自分", "そうすると、自分"),
            ("降りるのかそのまま", "降りるのか、そのまま"),
            ("Codex で", "Codexで"),
            ("、 Codex", "、Codex"),
            (" APIって", "APIって"),
            (" LLMに", "LLMに"),
            (" LLM に", "LLMに"),
            ("ファイル丸ごと", "ファイルを丸ごと"),
            ("ですかね。", "ですかね？"),
            ("じゃなくて全体", "じゃなくて、全体"),
            ("全体の。音声", "全体の音声"),
            ("踏まえて。処理", "踏まえて処理"),
            ("のであれば。その", "のであれば、その"),
            ("あれば。その", "あれば、その"),
            ("じゃなくてなんか全体", "じゃなくて、全体"),
            ("おきたい。んだけど。", "おきたいんだけど、"),
            ("おきたい。んだけど", "おきたいんだけど"),
            ("そうすると。余計", "\n\nそうすると、余計"),
            ("ですよ。とまず", "ですよ。\n\nまず"),
            ("まずスピーチ", "まず、スピーチ"),
            ("ですよね。この本では", "ですよね。\n\nこの本では"),
            ("よね。そうすると", "よね。\n\nそうすると"),
            ("思っています。つまり", "思っています。\n\nつまり"),
            ("思ってます。つまり", "思ってます。\n\nつまり"),
            ("んですよ。そういう", "んですよ。\n\nそういう"),
            ("ますよね。そうすると", "ますよね。\n\nそうすると"),
            ("できますよね。そうすると", "できますよね。\n\nそうすると")
        ]
        for (source, replacement) in replacements {
            current = current.replacingOccurrences(of: source, with: replacement)
        }
        return ensureTerminalPunctuation(collapseExcessiveLineBreaks(current))
    }

    private static func collapseExcessiveLineBreaks(_ text: String) -> String {
        var current = text
        while current.contains("\n\n\n") {
            current = current.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return current.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func ensureTerminalPunctuation(_ text: String) -> String {
        guard let last = text.last,
              !["。", "？", "?", "！", "!"].contains(last) else {
            return text
        }
        return text + "。"
    }
}

public struct MockPromptTextRefiner: PromptTextRefiner {
    public var refinedText: String
    public var engine: String

    public init(refinedText: String, engine: String = "MockPromptTextRefiner") {
        self.refinedText = refinedText
        self.engine = engine
    }

    public func refine(_ request: PromptTextRefinementRequest) async throws -> PromptTextRefinementResult {
        PromptTextRefinementResult(
            inputText: request.normalizedText,
            refinedText: refinedText,
            engine: engine
        )
    }
}
