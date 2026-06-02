import Foundation
import XCTest
@testable import VoiceAgentInputCore

final class UseCaseAndRepositoryTests: XCTestCase {
    func testUseCaseNormalizesPrompt() {
        let useCase = PromptNormalizationUseCase(entries: SeedDictionaries.codingAgentEntries)
        let result = useCase.normalize(rawText: "こーでっくすでぴーえぬぴーえむを確認")
        XCTAssertTrue(result.correctedText.contains("Codex"))
        XCTAssertTrue(result.correctedText.contains("pnpm"))
    }

    func testVoiceInputPipelineTranscribesThroughReplaceableEngineBeforeProcessing() async throws {
        let speechEngine = MockSpeechEngine()
        let pipeline = VoiceInputPipeline(
            speechEngine: speechEngine,
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        let result = try await pipeline.run(mockAudioText: "こーでっくすでブランチを確認して")

        XCTAssertEqual(result.transcript.text, "こーでっくすでブランチを確認して")
        XCTAssertTrue(result.insertion.text.contains("Codex"))
        XCTAssertTrue(result.insertion.text.contains("branch"))
    }

    func testVoiceInputPipelineRecordsAudioBeforeTranscriptionAndProcessing() async throws {
        let recorder = MockAudioRecorder(mockText: "くらのコードでタイプスクリプトを確認して")
        let permissionProvider = MockMicrophonePermissionProvider(status: .authorized)
        let speechEngine = MockSpeechEngine()
        let pipeline = VoiceInputPipeline(
            audioRecorder: recorder,
            microphonePermissionProvider: permissionProvider,
            speechEngine: speechEngine,
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        let result = try await pipeline.run()

        XCTAssertEqual(result.transcript.text, "くらのコードでタイプスクリプトを確認して")
        XCTAssertTrue(result.insertion.text.contains("Claude Code"))
        XCTAssertTrue(result.insertion.text.contains("TypeScript"))
        XCTAssertEqual(permissionProvider.requestAccessCallCount, 0)
    }

    func testVoiceInputPipelineReportsRecordedAudioForDebugObservability() async throws {
        let audio = RecordedAudio(
            data: Data("くらのコードでタイプスクリプトを確認して".utf8),
            formatDescription: "mock-text",
            durationSeconds: 4.2
        )
        let capturedAudio = RecordedAudioCapture()
        let pipeline = VoiceInputPipeline(
            audioRecorder: MockAudioRecorder(audio: audio),
            microphonePermissionProvider: MockMicrophonePermissionProvider(status: .authorized),
            speechEngine: MockSpeechEngine(),
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries),
            recordedAudioHandler: { capturedAudio.store($0) }
        )

        _ = try await pipeline.run()

        XCTAssertEqual(capturedAudio.value, audio)
    }

    func testVoiceInputPipelineKeepsTranscriptNormalizationRefinementAndInsertionStages() async throws {
        let pipeline = VoiceInputPipeline(
            speechEngine: MockSpeechEngine(),
            refiner: SuffixPromptRefiner(suffix: " please"),
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        let result = try await pipeline.run(mockAudioText: "くらのコードでタイプスクリプトエラーを直して")

        XCTAssertEqual(result.transcript.text, "くらのコードでタイプスクリプトエラーを直して")
        XCTAssertTrue(result.normalizedPrompt.normalizedText.contains("Claude Code"))
        XCTAssertTrue(result.normalizedPrompt.normalizedText.contains("TypeScript"))
        XCTAssertEqual(result.refinedPrompt.refinedText, result.normalizedPrompt.normalizedText + " please")
        XCTAssertEqual(result.insertion.text, result.refinedPrompt.refinedText)
    }

    func testSpeechTranscriptAccumulatorMergesPauseSplitSnapshots() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("最初の文章を入力しています")
        accumulator.record("次の文章も続けて入力しています")

        XCTAssertEqual(
            accumulator.bestText(),
            "最初の文章を入力しています次の文章も続けて入力しています"
        )
    }

    func testSpeechTranscriptAccumulatorDeduplicatesOverlappingSnapshots() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("Codexでテストを")
        accumulator.record("テストを追加して")
        accumulator.record("テストを追加してmake checkを実行")

        XCTAssertEqual(
            accumulator.bestText(),
            "Codexでテストを追加してmake checkを実行"
        )
    }

    func testSpeechTranscriptAccumulatorReplacesRevisedRollingSnapshot() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("佐藤さや蓄積マージの方法についてつい")
        accumulator.record("蓄積マージの方法について実装を入れてもらう")
        accumulator.record("蓄積マージの方法について実装を入れてもらったんだけどどうなってるかなって")

        XCTAssertEqual(
            accumulator.bestText(),
            "佐藤さや蓄積マージの方法について実装を入れてもらったんだけどどうなってるかなって"
        )
    }

    func testSpeechTranscriptAccumulatorRepairsLateSnapshotFromLastRepeatedAnchor() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("佐藤さや蓄積マージの方法について実装を入れてもらったんだけどどうなってるかなって蓄積マージの方法について")
        accumulator.record("蓄積マージの方法についてテストです")

        XCTAssertEqual(
            accumulator.bestText(),
            "佐藤さや蓄積マージの方法について実装を入れてもらったんだけどどうなってるかなって蓄積マージの方法についてテストです"
        )
    }

    func testSpeechTranscriptAccumulatorKeepsEarlierTextWhenFinalOnlyContainsLastChunk() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("録音開始から最初の依頼を話す")
        accumulator.record("次に補足を話す")

        XCTAssertEqual(
            accumulator.bestText(preferredFinalText: "次に補足を話す"),
            "録音開始から最初の依頼を話す次に補足を話す"
        )
    }

    func testSpeechTranscriptAccumulatorKeepsJapanesePauseSeparatedPromptWhenFinalOnlyContainsLastSentence() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("使い勝手はだいぶ良くなっている気がする")
        accumulator.record("というのも")
        accumulator.record("今ってレコードからストップまで全部見てくれているんですよね")

        XCTAssertEqual(
            accumulator.bestText(preferredFinalText: "今ってレコードからストップまで全部見てくれているんですよね"),
            "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね"
        )
    }

    func testSpeechTranscriptAccumulatorKeepsPauseSeparatedPromptAcrossRollingRevisionsAndFinalRegression() {
        var accumulator = SpeechTranscriptAccumulator()

        accumulator.record("使い勝手はだいぶ良くなっている気がする")
        accumulator.record("使い勝手はだいぶ良くなっている気がするというのも")
        accumulator.record("というのも今ってレコードからストップまで全部見てくれているんですよね")

        XCTAssertEqual(
            accumulator.bestText(preferredFinalText: "今ってレコードからストップまで全部見てくれているんですよね"),
            "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね"
        )
    }

    func testJapanesePunctuationPromptRefinerPunctuatesPauseSeparatedRecordingScenario() async throws {
        let normalized = NormalizedPrompt(
            rawText: "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね",
            normalizedText: "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね",
            corrections: []
        )

        let refined = try await JapanesePunctuationPromptRefiner().refine(normalized)

        XCTAssertEqual(
            refined.refinedText,
            "使い勝手はだいぶ良くなっている気がする。というのも、今ってレコードからストップまで全部見てくれているんですよね"
        )
    }

    func testPromptProcessingPipelineRunsAfterSTTWithoutAudioDependencies() async throws {
        let pipeline = PromptProcessingPipeline(
            refiner: SuffixPromptRefiner(suffix: " please"),
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        let result = try await pipeline.process(
            transcript: Transcript(text: "くらのコードでタイプスクリプトを確認")
        )

        XCTAssertEqual(result.transcript.text, "くらのコードでタイプスクリプトを確認")
        XCTAssertTrue(result.normalizedPrompt.normalizedText.contains("Claude Code"))
        XCTAssertTrue(result.normalizedPrompt.normalizedText.contains("TypeScript"))
        XCTAssertEqual(result.refinedPrompt.refinedText, result.normalizedPrompt.normalizedText + " please")
        XCTAssertEqual(result.insertion.text, result.refinedPrompt.refinedText)
    }

    func testNoOpPromptRefinerPreservesNormalizedPrompt() async throws {
        let normalized = NormalizedPrompt(
            rawText: "こーでっくす",
            normalizedText: "Codex",
            corrections: []
        )

        let refined = try await NoOpPromptRefiner().refine(normalized)

        XCTAssertEqual(refined.normalizedText, "Codex")
        XCTAssertEqual(refined.refinedText, "Codex")
        XCTAssertEqual(refined.changes, [])
    }

    func testJapanesePunctuationPromptRefinerAddsLightweightPunctuation() async throws {
        let normalized = NormalizedPrompt(
            rawText: "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね",
            normalizedText: "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね",
            corrections: []
        )

        let refined = try await JapanesePunctuationPromptRefiner().refine(normalized)

        XCTAssertEqual(
            refined.refinedText,
            "使い勝手はだいぶ良くなっている気がする。というのも、今ってレコードからストップまで全部見てくれているんですよね"
        )
        XCTAssertEqual(refined.changes.count, 1)
    }

    func testPromptTransformsExposeTextToTextConvenience() async throws {
        let context = NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        let normalizedText = try DictionaryPromptNormalizer().normalizeText(
            "くらのコードでタイプスクリプトを確認",
            context: context
        )
        let refinedText = try await NoOpPromptRefiner().refineText(normalizedText)

        XCTAssertTrue(normalizedText.contains("Claude Code"))
        XCTAssertTrue(normalizedText.contains("TypeScript"))
        XCTAssertEqual(refinedText, normalizedText)
    }

    func testPromptTextTransformPipelineComposesDictionaryAndRefinementLayers() async throws {
        let context = NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        let pipeline = PromptTextTransformPipeline(transforms: [
            DictionaryPromptTextTransform(context: context),
            RefinementPromptTextTransform(refiner: SuffixPromptRefiner(suffix: " please"))
        ])

        let output = try await pipeline.transform("くらのコードでタイプスクリプトを確認")

        XCTAssertTrue(output.contains("Claude Code"))
        XCTAssertTrue(output.contains("TypeScript"))
        XCTAssertTrue(output.hasSuffix(" please"))
    }

    func testLocalContextCandidateGenerationFindsRepeatedDeveloperTerms() {
        let texts = [
            "Fix the SwiftUI preview and call the API from Codex.",
            "The SwiftUI view should not block the API call.",
            "Codex should preserve the JSON payload.",
            "ProjectSpecificName appears more than once.",
            "ProjectSpecificName appears again."
        ]

        let candidates = LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
            .candidates(from: texts)

        XCTAssertTrue(candidates.contains {
            $0.correctedPhrase == "SwiftUI" &&
            $0.rawPhrase == "すいふとゆーあい" &&
            $0.occurrenceCount == 2
        })
        XCTAssertTrue(candidates.contains {
            $0.correctedPhrase == "API" &&
            $0.rawPhrase == "えーぴーあい"
        })
        XCTAssertTrue(candidates.contains {
            $0.correctedPhrase == "ProjectSpecificName" &&
            $0.rawPhrase == "project specific name"
        })
        XCTAssertTrue(candidates.allSatisfy { $0.autoApplyAllowed })
    }

    func testLocalAgentHistoryTextProviderReadsBoundedLocalHistories() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let codexDirectory = home.appendingPathComponent(".codex")
        let claudeDirectory = home.appendingPathComponent(".claude/projects/project-a")
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: claudeDirectory, withIntermediateDirectories: true)

        try "codex history SwiftUI API".write(
            to: codexDirectory.appendingPathComponent("history.jsonl"),
            atomically: true,
            encoding: .utf8
        )
        try "claude jsonl Codex".write(
            to: claudeDirectory.appendingPathComponent("session.jsonl"),
            atomically: true,
            encoding: .utf8
        )
        try "0123456789abcdef".write(
            to: claudeDirectory.appendingPathComponent("session.md"),
            atomically: true,
            encoding: .utf8
        )
        try "ignored binary".write(
            to: claudeDirectory.appendingPathComponent("session.bin"),
            atomically: true,
            encoding: .utf8
        )

        let provider = LocalAgentHistoryTextProvider(
            homeDirectory: home,
            maximumClaudeProjectFiles: 2,
            maximumBytesPerFile: 10,
            allowedClaudeProjectExtensions: ["jsonl", "md"]
        )
        let texts = try provider.historyTexts()

        XCTAssertTrue(texts.contains { $0.contains("codex hist") })
        XCTAssertTrue(texts.contains { $0.contains("claude jso") })
        XCTAssertTrue(texts.contains("0123456789"))
        XCTAssertFalse(texts.contains { $0.contains("ignored binary") })
    }

    func testLocalAgentHistoryTextProviderExtractsUserTextFromStructuredJSONL() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let codexDirectory = home.appendingPathComponent(".codex")
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)

        try """
        {"role":"assistant","content":"AssistantOnlyTerm should not train the dictionary."}
        {"role":"user","content":"Please fix SwiftUI previews and JSON fixtures."}
        {"message":{"role":"user","content":[{"type":"text","text":"Codex should preserve MCP settings."}]}}
        {"text":"Fallback project note mentions Claude Code."}
        """.write(
            to: codexDirectory.appendingPathComponent("history.jsonl"),
            atomically: true,
            encoding: .utf8
        )

        let texts = try LocalAgentHistoryTextProvider(homeDirectory: home).historyTexts()
        let joined = texts.joined(separator: "\n")

        XCTAssertTrue(joined.contains("SwiftUI previews"))
        XCTAssertTrue(joined.contains("Codex should preserve MCP settings"))
        XCTAssertTrue(joined.contains("Claude Code"))
        XCTAssertFalse(joined.contains("AssistantOnlyTerm"))
    }

    func testLocalAgentHistoryTextProviderSkipsStructuredJSONWithoutUserText() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let codexDirectory = home.appendingPathComponent(".codex")
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)

        try """
        {"session_id":"metadata-only","updated_at":"2026-05-31T00:00:00Z"}
        {"role":"assistant","content":"AssistantOnlyTerm should not train the dictionary."}
        """.write(
            to: codexDirectory.appendingPathComponent("history.jsonl"),
            atomically: true,
            encoding: .utf8
        )

        let texts = try LocalAgentHistoryTextProvider(homeDirectory: home).historyTexts()

        XCTAssertFalse(texts.joined(separator: "\n").contains("metadata-only"))
        XCTAssertFalse(texts.joined(separator: "\n").contains("AssistantOnlyTerm"))
    }

    func testLocalAgentHistoryTextProviderPrefersRecentlyModifiedClaudeProjectFiles() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let claudeDirectory = home.appendingPathComponent(".claude/projects/project-a")
        try FileManager.default.createDirectory(at: claudeDirectory, withIntermediateDirectories: true)

        let oldURL = claudeDirectory.appendingPathComponent("old-session.jsonl")
        let newURL = claudeDirectory.appendingPathComponent("new-session.jsonl")
        try "old SwiftUI".write(to: oldURL, atomically: true, encoding: .utf8)
        try "new ProjectSpecificName".write(to: newURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 10)],
            ofItemAtPath: oldURL.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 20)],
            ofItemAtPath: newURL.path
        )

        let texts = try LocalAgentHistoryTextProvider(
            homeDirectory: home,
            maximumClaudeProjectFiles: 1
        ).historyTexts()
        let joined = texts.joined(separator: "\n")

        XCTAssertTrue(joined.contains("new ProjectSpecificName"))
        XCTAssertFalse(joined.contains("old SwiftUI"))
    }

    func testAgentHistoryLearningModeUseCaseLoadsHistoryAndGeneratesCandidates() throws {
        let provider = StubAgentHistoryTextProvider(texts: [
            "Fix SwiftUI in Codex.",
            "SwiftUI should preserve JSON.",
            "Codex writes JSON fixtures."
        ])
        let result = try AgentHistoryLearningModeUseCase(
            historyProvider: provider,
            contextCandidateGenerationUseCase: LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
        ).generateCandidates()

        XCTAssertEqual(result.scannedTextCount, 3)
        XCTAssertTrue(result.candidates.contains {
            $0.correctedPhrase == "SwiftUI" &&
            $0.rawPhrase == "すいふとゆーあい"
        })
        XCTAssertTrue(result.candidates.contains {
            $0.correctedPhrase == "JSON" &&
            $0.rawPhrase == "じぇいそん"
        })
    }

    func testAgentHistoryLearningModeSkipsExistingDictionaryEntries() throws {
        let provider = StubAgentHistoryTextProvider(texts: [
            "Fix SwiftUI in Codex.",
            "SwiftUI should preserve JSON.",
            "Codex writes JSON fixtures."
        ])
        let existingEntries = [
            DictionaryEntry(
                spokenForms: ["すいふとゆーあい"],
                canonical: "SwiftUI",
                kind: .framework,
                scope: .user,
                confidence: 0.8,
                autoApply: true
            )
        ]

        let result = try AgentHistoryLearningModeUseCase(
            historyProvider: provider,
            contextCandidateGenerationUseCase: LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
        ).generateCandidates(existingEntries: existingEntries)

        XCTAssertEqual(result.skippedExistingCandidateCount, 1)
        XCTAssertFalse(result.candidates.contains { $0.correctedPhrase == "SwiftUI" })
        XCTAssertTrue(result.candidates.contains { $0.correctedPhrase == "JSON" })
    }

    func testAgentHistoryLearningModeCanGenerateRepositoryScopedCandidates() throws {
        let provider = StubAgentHistoryTextProvider(texts: [
            "SwiftUI renders JSON previews.",
            "SwiftUI loads JSON fixtures."
        ])

        let result = try AgentHistoryLearningModeUseCase(
            historyProvider: provider,
            contextCandidateGenerationUseCase: LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
        ).generateCandidates(scope: .repository)

        XCTAssertFalse(result.candidates.isEmpty)
        XCTAssertTrue(result.candidates.allSatisfy { $0.suggestedScope == .repository })
    }

    func testLearningSourceSelectionReportsSelectedKinds() {
        XCTAssertEqual(
            LearningSourceSelection(includeAgentHistory: true, includeRepositoryVocabulary: true).selectedKinds,
            [.agentHistory, .repositoryVocabulary]
        )
        XCTAssertEqual(
            LearningSourceSelection(includeAgentHistory: false, includeRepositoryVocabulary: true).selectedKinds,
            [.repositoryVocabulary]
        )
        XCTAssertTrue(
            LearningSourceSelection(includeAgentHistory: false, includeRepositoryVocabulary: false).isEmpty
        )
    }

    func testAgentHistoryLearningModeReportsSourceTextCounts() throws {
        let provider = StubAgentHistoryTextProvider(texts: [
            "SwiftUI renders JSON previews.",
            "SwiftUI loads JSON fixtures."
        ])
        let repositorySource = RepositoryVocabularyLearningSource(
            startingURL: URL(fileURLWithPath: "/tmp/VoiceAgentInput"),
            repositoryContextProvider: StubRepositoryContextProvider(
                context: RepositoryContext(rootPath: "/tmp/VoiceAgentInput", branchName: "feature/context")
            ),
            repositoryVocabularyFilePathProvider: StubRepositoryVocabularyFilePathProvider(filePaths: ["Package.swift"])
        )

        let result = try AgentHistoryLearningModeUseCase(
            learningSources: [provider, repositorySource],
            contextCandidateGenerationUseCase: LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
        ).generateCandidates()

        XCTAssertEqual(result.scannedTextCount, 3)
        XCTAssertEqual(result.sourceTextCounts["agentHistory"], 2)
        XCTAssertEqual(result.sourceTextCounts["repositoryVocabulary"], 1)
    }

    func testSpeechRecognitionHintsUseDictionaryEntriesForContextualStrings() {
        let entries = [
            DictionaryEntry(
                spokenForms: ["ぷろじぇくとぼいす", " Project Voice "],
                canonical: "ProjectVoice",
                kind: .projectTerm,
                scope: .repository,
                confidence: 0.9,
                autoApply: true
            ),
            DictionaryEntry(
                spokenForms: ["ぷろじぇくとぼいす"],
                canonical: "ProjectVoice",
                kind: .projectTerm,
                scope: .repository,
                confidence: 0.9,
                autoApply: true
            ),
            DictionaryEntry(
                spokenForms: ["   "],
                canonical: "   ",
                kind: .phrase,
                scope: .user,
                confidence: 0.5,
                autoApply: false
            )
        ]

        let hints = SpeechRecognitionHintsUseCase().hints(from: entries)

        XCTAssertEqual(hints.contextualStrings, [
            "ProjectVoice",
            "project voice",
            "プロジェクト ボイス",
            "プロジェクトボイス"
        ])
    }

    func testSpeechRecognitionHintsPreferRecognitionHintsOverCorrectionForms() {
        let entries = [
            DictionaryEntry(
                spokenForms: ["くらのコード"],
                canonical: "Claude Code",
                recognitionHints: [" Claude Code ", "クロードコード"],
                kind: .toolName,
                scope: .user,
                confidence: 0.9,
                autoApply: true
            )
        ]

        let hints = SpeechRecognitionHintsUseCase().hints(from: entries)

        XCTAssertEqual(hints.contextualStrings, ["Claude Code", "クロードコード"])
        XCTAssertFalse(hints.contextualStrings.contains("くらのコード"))
    }

    func testSpeechRecognitionHintsCanBeBounded() {
        let entries = [
            DictionaryEntry(
                spokenForms: ["one", "two"],
                canonical: "Canonical",
                recognitionHints: ["Canonical", "one", "two"],
                kind: .phrase,
                scope: .user,
                confidence: 0.9,
                autoApply: true
            )
        ]

        let hints = SpeechRecognitionHintsUseCase(maximumContextualStrings: 2).hints(from: entries)

        XCTAssertEqual(hints.contextualStrings, ["Canonical", "one"])
    }

    func testLocalContextModelFeedsRecognitionHintsAndPostSTTEntries() {
        let learningResult = AgentHistoryLearningModeResult(
            scannedTextCount: 2,
            sourceTextCounts: ["agentHistory": 2],
            candidates: [
                CorrectionCandidate(
                    rawPhrase: "すいふとゆーあい",
                    correctedPhrase: "SwiftUI",
                    confidence: 0.8,
                    occurrenceCount: 2,
                    reason: "Found 2 uses in local learning sources.",
                    suggestedScope: .user,
                    autoApplyAllowed: true
                )
            ]
        )

        let model = LocalContextModelBuildUseCase(
            seedEntries: []
        ).build(learningResult: learningResult, rebuiltAt: Date(timeIntervalSince1970: 1_800))

        XCTAssertEqual(model.sourceTextCounts["agentHistory"], 2)
        XCTAssertEqual(model.sourceKinds, ["agentHistory"])
        XCTAssertEqual(model.lastRebuiltAt, Date(timeIntervalSince1970: 1_800))
        XCTAssertEqual(model.generatedCandidateCount, 1)
        XCTAssertEqual(model.postSTTEntries.map(\.canonical), ["SwiftUI"])
        XCTAssertEqual(
            model.recognitionHints().contextualStrings,
            ["SwiftUI", "すいふとゆーあい"]
        )
    }

    func testLocalContextModelCanExcludeGeneratedCandidatesFromRuntimeEntries() {
        let learningResult = AgentHistoryLearningModeResult(
            scannedTextCount: 1,
            sourceTextCounts: ["agentHistory": 1],
            candidates: [
                CorrectionCandidate(
                    rawPhrase: "じぇいそん",
                    correctedPhrase: "JSON",
                    confidence: 0.7,
                    occurrenceCount: 1,
                    reason: "Found in local learning sources.",
                    suggestedScope: .user,
                    autoApplyAllowed: true
                )
            ]
        )

        let model = LocalContextModelBuildUseCase(seedEntries: [])
            .build(learningResult: learningResult, includeGeneratedCandidates: false)

        XCTAssertTrue(model.postSTTEntries.isEmpty)
        XCTAssertTrue(model.recognitionHints().contextualStrings.isEmpty)
        XCTAssertEqual(model.generatedCandidateCount, 1)
        XCTAssertEqual(model.sourceTextCounts["agentHistory"], 1)
    }

    func testLocalContextModelDataUseCaseRebuildsAndPersistsModel() throws {
        let learningResult = AgentHistoryLearningModeResult(
            scannedTextCount: 1,
            sourceTextCounts: ["repositoryVocabulary": 1],
            candidates: [
                CorrectionCandidate(
                    rawPhrase: "めいんぶらんち",
                    correctedPhrase: "main",
                    confidence: 0.75,
                    occurrenceCount: 1,
                    reason: "Found in repository vocabulary.",
                    suggestedScope: .user,
                    autoApplyAllowed: true
                )
            ]
        )
        let repository = InMemoryLocalContextModelRepository()

        let model = try LocalContextModelDataUseCase(
            repository: repository,
            buildUseCase: LocalContextModelBuildUseCase(seedEntries: [])
        ).rebuildModel(learningResult: learningResult, rebuiltAt: Date(timeIntervalSince1970: 2_400))

        XCTAssertEqual(model.postSTTEntries.map(\.canonical), ["main"])
        XCTAssertEqual(model.sourceTextCounts["repositoryVocabulary"], 1)
        XCTAssertEqual(model.sourceKinds, ["repositoryVocabulary"])
        XCTAssertEqual(model.lastRebuiltAt, Date(timeIntervalSince1970: 2_400))
        XCTAssertEqual(try repository.loadModel(), model)
    }

    func testLocalContextModelDocumentCodecRoundTrip() throws {
        let model = LocalContextModel(
            entries: [
                DictionaryEntry(
                    spokenForms: ["ぷろじぇくとぼいす"],
                    canonical: "ProjectVoice",
                    recognitionHints: ["ProjectVoice"],
                    kind: .projectTerm,
                    scope: .user,
                    confidence: 0.9,
                    autoApply: true
                )
            ],
            sourceTextCounts: ["agentHistory": 2],
            generatedCandidateCount: 1,
            lastRebuiltAt: Date(timeIntervalSince1970: 3_600),
            sourceKinds: ["agentHistory"]
        )

        let data = try LocalContextModelDocumentCodec().encode(model)
        let decoded = try LocalContextModelDocumentCodec().decode(data)

        XCTAssertEqual(decoded, model)
        XCTAssertTrue(String(data: data, encoding: .utf8)?.contains("\"schemaVersion\" : 1") == true)
        XCTAssertTrue(String(data: data, encoding: .utf8)?.contains("\"lastRebuiltAt\"") == true)
    }

    func testLocalContextModelDocumentCodecDecodesLegacyModelWithoutRebuildMetadata() throws {
        let legacyJSON = """
        {
          "schemaVersion": 1,
          "model": {
            "entries": [],
            "sourceTextCounts": {
              "agentHistory": 2
            },
            "generatedCandidateCount": 1
          }
        }
        """

        let decoded = try LocalContextModelDocumentCodec().decode(Data(legacyJSON.utf8))

        XCTAssertEqual(decoded.sourceTextCounts["agentHistory"], 2)
        XCTAssertEqual(decoded.generatedCandidateCount, 1)
        XCTAssertNil(decoded.lastRebuiltAt)
        XCTAssertTrue(decoded.sourceKinds.isEmpty)
    }

    func testLocalContextModelStatusWarnsWhenModelHasNeverBeenRebuilt() {
        let warnings = LocalContextModelStatusUseCase()
            .warnings(model: LocalContextModel(), configuredRepositoryPath: nil)

        XCTAssertEqual(warnings, ["Local context model has not been rebuilt yet."])
    }

    func testLocalContextModelStatusWarnsWhenConfiguredRepositoryIsMissingFromModel() {
        let model = LocalContextModel(
            lastRebuiltAt: Date(timeIntervalSince1970: 1_800),
            sourceKinds: ["agentHistory"]
        )

        let warnings = LocalContextModelStatusUseCase()
            .warnings(model: model, configuredRepositoryPath: "/tmp/repo")

        XCTAssertEqual(warnings, [
            "Repository folder is configured, but repository vocabulary is not in the saved model. Rebuild to include it."
        ])
    }

    func testLocalContextModelStatusWarnsWhenModelContainsRepositoryWithoutConfiguredRepository() {
        let model = LocalContextModel(
            lastRebuiltAt: Date(timeIntervalSince1970: 1_800),
            sourceKinds: ["repositoryVocabulary"]
        )

        let warnings = LocalContextModelStatusUseCase()
            .warnings(model: model, configuredRepositoryPath: nil)

        XCTAssertEqual(warnings, [
            "Saved model includes repository vocabulary, but no repository folder is configured. Rebuild if this source should no longer be used."
        ])
    }

    func testLocalContextModelStatusDoesNotWarnWhenConfiguredSourcesMatch() {
        let model = LocalContextModel(
            lastRebuiltAt: Date(timeIntervalSince1970: 1_800),
            sourceKinds: ["agentHistory", "repositoryVocabulary"]
        )

        let warnings = LocalContextModelStatusUseCase()
            .warnings(model: model, configuredRepositoryPath: "  /tmp/repo  ")

        XCTAssertTrue(warnings.isEmpty)
    }

    func testJSONLocalContextModelRepositoryRoundTripAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = JSONLocalContextModelRepository(
            fileURL: directory.appendingPathComponent("local-context-model.json")
        )
        let model = LocalContextModel(
            entries: [
                DictionaryEntry(
                    spokenForms: ["すいふとゆーあい"],
                    canonical: "SwiftUI",
                    kind: .framework,
                    scope: .user,
                    confidence: 0.8,
                    autoApply: true
                )
            ],
            sourceTextCounts: ["agentHistory": 2],
            generatedCandidateCount: 1
        )

        XCTAssertEqual(try repository.loadModel(), LocalContextModel())

        try LocalContextModelDataUseCase(repository: repository).importModel(model)
        XCTAssertEqual(try LocalContextModelDataUseCase(repository: repository).exportModel(), model)

        try LocalContextModelDataUseCase(repository: repository).deleteLocalContextModel()
        XCTAssertEqual(try repository.loadModel(), LocalContextModel())
    }

    func testVoiceInputPipelineRequestsMicrophonePermissionWhenNeeded() async throws {
        let permissionProvider = MockMicrophonePermissionProvider(status: .notDetermined, requestedStatus: .authorized)
        let pipeline = VoiceInputPipeline(
            audioRecorder: MockAudioRecorder(mockText: "こーでっくすでブランチを確認して"),
            microphonePermissionProvider: permissionProvider,
            speechEngine: MockSpeechEngine(),
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        let result = try await pipeline.run()

        XCTAssertTrue(result.insertion.text.contains("Codex"))
        XCTAssertEqual(permissionProvider.requestAccessCallCount, 1)
    }

    func testSpeechRecognitionPermissionRequestsAccessWhenNeeded() async throws {
        let permissionProvider = MockSpeechRecognitionPermissionProvider(status: .notDetermined, requestedStatus: .authorized)
        let useCase = SpeechRecognitionPermissionUseCase(provider: permissionProvider)

        let status = try await useCase.ensureTranscriptionAllowed()

        XCTAssertEqual(status, .authorized)
        XCTAssertEqual(permissionProvider.requestAccessCallCount, 1)
    }

    func testSpeechRecognitionPermissionRejectsDeniedStatus() async {
        let permissionProvider = MockSpeechRecognitionPermissionProvider(status: .denied)
        let useCase = SpeechRecognitionPermissionUseCase(provider: permissionProvider)

        do {
            _ = try await useCase.ensureTranscriptionAllowed()
            XCTFail("Expected speech recognition permission denial")
        } catch {
            XCTAssertEqual(error as? SpeechRecognitionPermissionError, .transcriptionNotAllowed(status: .denied))
            XCTAssertEqual(permissionProvider.requestAccessCallCount, 0)
        }
    }

    func testPermissionStatusUseCaseReadsCurrentAdapterStatuses() {
        let useCase = PermissionStatusUseCase(
            microphonePermissionProvider: MockMicrophonePermissionProvider(status: .authorized),
            speechRecognitionPermissionProvider: MockSpeechRecognitionPermissionProvider(status: .denied),
            accessibilityPermissionProvider: MockAccessibilityPermissionProvider(status: .notTrusted),
            inputMonitoringPermissionProvider: MockInputMonitoringPermissionProvider(status: .trusted)
        )

        XCTAssertEqual(useCase.currentStatus(), PermissionStatusSnapshot(
            microphone: .authorized,
            speechRecognition: .denied,
            accessibility: .notTrusted,
            inputMonitoring: .trusted
        ))
    }

    func testAppleSpeechEngineRequiresOnDeviceRecognitionByDefault() {
        let engine = AppleSpeechEngine()

        XCTAssertTrue(engine.requiresOnDeviceRecognition)
        XCTAssertEqual(engine.localeIdentifier, "ja-JP")
        XCTAssertEqual(engine.recognitionHints, SpeechRecognitionHints())
    }

    func testAppleSpeechEngineAppliesContextualStringsToRecognitionRequest() {
        let engine = AppleSpeechEngine(
            recognitionHints: SpeechRecognitionHints(contextualStrings: ["ProjectVoice", "Claude Code"])
        )

        let request = engine.recognitionRequest(url: URL(fileURLWithPath: "/tmp/audio.caf"))

        XCTAssertTrue(request.shouldReportPartialResults)
        XCTAssertTrue(request.requiresOnDeviceRecognition)
        XCTAssertEqual(request.contextualStrings, ["ProjectVoice", "Claude Code"])
    }

    func testAppleSpeechEngineUsesExistingTemporaryRecordingFileAndDeletesItAfterOperation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let recordingURL = directory.appendingPathComponent("recording.caf")
        try Data("audio".utf8).write(to: recordingURL, options: .atomic)
        let engine = AppleSpeechEngine()
        let audio = RecordedAudio(
            data: Data(),
            formatDescription: "caf/aac",
            durationSeconds: 1,
            temporaryFileURL: recordingURL,
            shouldDeleteTemporaryFile: true,
            byteCount: 5
        )

        let usedURL = try await engine.withRecognitionAudioFile(for: audio) { url in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            return url
        }

        XCTAssertEqual(usedURL, recordingURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: recordingURL.path))
    }

    func testAppleSpeechEngineStillMaterializesDataBackedAudioTemporarily() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let engine = AppleSpeechEngine(temporaryDirectory: directory)
        let audio = RecordedAudio(
            data: Data("audio".utf8),
            formatDescription: "caf/aac",
            durationSeconds: 1
        )

        let usedURL = try await engine.withRecognitionAudioFile(for: audio) { url in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertEqual(try Data(contentsOf: url), Data("audio".utf8))
            return url
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: usedURL.path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testAppleSpeechEngineMapsNoSpeechDetectedError() {
        let error = NSError(
            domain: "kAFAssistantErrorDomain",
            code: 1110,
            userInfo: [NSLocalizedDescriptionKey: "No speech detected"]
        )

        XCTAssertEqual(AppleSpeechEngineError.map(error), .noSpeechDetected)
    }

    func testSpeechTranscriptAccumulatorKeepsFullPartialWhenFinalOnlyContainsLastUtterance() {
        var accumulator = SpeechTranscriptAccumulator()
        accumulator.record("使い勝手はだいぶ良くなっている気がする")
        accumulator.record("使い勝手はだいぶ良くなっている気がするというのも")
        accumulator.record("使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね")

        let best = accumulator.bestText(preferredFinalText: "今ってレコードからストップまで全部見てくれているんですよね")

        XCTAssertEqual(best, "使い勝手はだいぶ良くなっている気がするというのも今ってレコードからストップまで全部見てくれているんですよね")
    }

    func testTemporaryRecordedAudioFileStoreRemovesFileAfterSuccessfulOperation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = TemporaryRecordedAudioFileStore(directoryURL: directory)
        let audio = RecordedAudio(
            data: Data("audio".utf8),
            formatDescription: "caf/aac",
            durationSeconds: 1
        )

        let existedDuringOperation = try await store.withRecordedAudioFile(audio) { url in
            FileManager.default.fileExists(atPath: url.path)
        }

        XCTAssertTrue(existedDuringOperation)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testTemporaryRecordedAudioFileStoreRemovesFileAfterFailedOperation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = TemporaryRecordedAudioFileStore(directoryURL: directory)
        let audio = RecordedAudio(
            data: Data("audio".utf8),
            formatDescription: "caf/aac",
            durationSeconds: 1
        )

        do {
            try await store.withRecordedAudioFile(audio) { _ in
                throw TemporaryRecordedAudioFileStoreTestError.expected
            }
            XCTFail("Expected temporary audio operation to fail")
        } catch {
            XCTAssertEqual(error as? TemporaryRecordedAudioFileStoreTestError, .expected)
        }

        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testVoiceInputPipelineDoesNotRecordWhenMicrophonePermissionIsDenied() async {
        let permissionProvider = MockMicrophonePermissionProvider(status: .denied)
        let pipeline = VoiceInputPipeline(
            audioRecorder: MockAudioRecorder(mockText: "recording should not be consumed"),
            microphonePermissionProvider: permissionProvider,
            speechEngine: MockSpeechEngine(),
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        do {
            _ = try await pipeline.run()
            XCTFail("Expected microphone permission denial")
        } catch {
            XCTAssertEqual(error as? VoiceInputPipelineError, .microphonePermissionDenied(status: .denied))
            XCTAssertEqual(permissionProvider.requestAccessCallCount, 0)
        }
    }

    func testVoiceInputPipelineRequiresRecorderForRecordPath() async {
        let pipeline = VoiceInputPipeline(
            speechEngine: MockSpeechEngine(),
            normalizationContext: NormalizationContext(entries: SeedDictionaries.codingAgentEntries)
        )

        do {
            _ = try await pipeline.run()
            XCTFail("Expected recorder unavailable error")
        } catch {
            XCTAssertEqual(error as? VoiceInputPipelineError, .audioRecorderUnavailable)
        }
    }

    func testAgentHistoryLearningModelEvolvesRuleBasedNormalizationForProjectTerms() throws {
        let historyProvider = StubAgentHistoryTextProvider(texts: [
            "ProjectSpecificName appears in this repository prompt.",
            "Please preserve ProjectSpecificName when editing docs."
        ])
        let learningResult = try AgentHistoryLearningModeUseCase(
            historyProvider: historyProvider,
            contextCandidateGenerationUseCase: LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
        ).generateCandidates(existingEntries: [])

        guard learningResult.candidates.contains(where: {
            $0.rawPhrase == "project specific name" &&
                $0.correctedPhrase == "ProjectSpecificName"
        }) else {
            return XCTFail("Expected ProjectSpecificName learning candidate")
        }

        let model = LocalContextModelBuildUseCase(seedEntries: [])
            .build(learningResult: learningResult)
        let normalized = PromptNormalizationUseCase(entries: model.postSTTEntries)
            .normalize(rawText: "project specific nameの設定を直して")

        XCTAssertEqual(normalized.correctedText, "ProjectSpecificName の設定を直して")
    }

    func testPromptInsertionRequiresCompletedUserAction() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let prompt = PromptInsertion(text: "Claude Code で確認して")

        XCTAssertThrowsError(try useCase.insert(prompt, afterUserAction: false)) { error in
            XCTAssertEqual(error as? PromptInsertionError, .userActionRequired)
        }
        XCTAssertTrue(insertionController.insertedRequests.isEmpty)
    }

    func testPromptInsertionUsesPromptTextWithoutSubmitting() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let prompt = PromptInsertion(text: "Claude Code で確認して")

        try useCase.insert(prompt, afterUserAction: true)

        XCTAssertEqual(insertionController.insertedRequests, [
            TextInsertionRequest(text: "Claude Code で確認して")
        ])
    }

    func testLocalAppDataStoreCreatesRepositoryDirectoryForSettings() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LocalAppDataStore(directoryURL: directory)
        let repository = try store.settingsRepository()

        try repository.saveSettings(AppSettings())

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertEqual(try repository.loadSettings(), AppSettings())
    }

    func testJSONAppSettingsRepositoryRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LocalAppDataStore(directoryURL: directory)
        let repository = try store.settingsRepository()

        XCTAssertEqual(try repository.loadSettings(), AppSettings())

        try repository.saveSettings(AppSettings(
            repositoryPath: "/tmp/repo",
            voiceInputShortcut: KeyboardShortcut(key: "s", modifiers: [.control, .shift]),
            voiceInputTriggerMode: .toggleRecording
        ))

        XCTAssertEqual(try repository.loadSettings(), AppSettings(
            repositoryPath: "/tmp/repo",
            voiceInputShortcut: KeyboardShortcut(key: "s", modifiers: [.control, .shift]),
            voiceInputTriggerMode: .toggleRecording
        ))
    }

    func testJSONAppSettingsRepositoryDefaultsMissingNewFields() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent("settings.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try #"{"repositoryPath":"/tmp/repo"}"#.data(using: .utf8)!.write(to: fileURL)

        let settings = try JSONAppSettingsRepository(fileURL: fileURL).loadSettings()

        XCTAssertEqual(settings, AppSettings(repositoryPath: "/tmp/repo"))
        XCTAssertEqual(settings.voiceInputShortcut, .defaultVoiceInput)
        XCTAssertEqual(settings.voiceInputTriggerMode, .pressAndHold)
    }

    func testAppSettingsKeepsLearningScopeFixedToUser() {
        XCTAssertEqual(AppSettings().preferredLearningScope, .user)
        XCTAssertEqual(AppSettings(repositoryPath: "/tmp/repo").preferredLearningScope, .user)
    }

    func testAppSettingsUseCaseSavesRepositoryAndHotkeySettings() throws {
        let repository = InMemoryAppSettingsRepository()
        let useCase = AppSettingsUseCase(repository: repository)

        let repositorySettings = try useCase.saveRepositoryPath("/tmp/repo")

        XCTAssertEqual(repositorySettings.repositoryPath, "/tmp/repo")
        XCTAssertEqual(try repository.loadSettings(), repositorySettings)

        let hotkeySettings = try useCase.saveVoiceInputHotkey(
            shortcut: KeyboardShortcut(key: "s", modifiers: [.control, .shift]),
            triggerMode: .toggleRecording
        )
        XCTAssertEqual(hotkeySettings.voiceInputShortcut, KeyboardShortcut(key: "s", modifiers: [.control, .shift]))
        XCTAssertEqual(hotkeySettings.voiceInputTriggerMode, .toggleRecording)
        XCTAssertEqual(try repository.loadSettings().voiceInputTriggerMode, .toggleRecording)
    }

    func testVoiceInputHotkeyUseCaseSupportsPressHoldAndToggleTriggers() {
        let useCase = VoiceInputHotkeyUseCase()

        XCTAssertEqual(
            useCase.action(triggerMode: .pressAndHold, event: .pressed, isRecording: false),
            .startRecording
        )
        XCTAssertEqual(
            useCase.action(triggerMode: .pressAndHold, event: .released, isRecording: true),
            .stopRecording
        )
        XCTAssertEqual(
            useCase.action(triggerMode: .pressAndHold, event: .pressed, isRecording: true),
            .none
        )
        XCTAssertEqual(
            useCase.action(triggerMode: .toggleRecording, event: .pressed, isRecording: false),
            .startRecording
        )
        XCTAssertEqual(
            useCase.action(triggerMode: .toggleRecording, event: .pressed, isRecording: true),
            .stopRecording
        )
        XCTAssertEqual(
            useCase.action(triggerMode: .toggleRecording, event: .released, isRecording: true),
            .none
        )
    }

    func testRecordingFeedbackPresentationGuidesPressAndHoldStopToPaste() {
        let presentation = RecordingFeedbackPresentationUseCase().presentation(
            level: 0.22,
            hasDetectedVoice: true,
            elapsedSeconds: 5.4,
            triggerMode: .pressAndHold
        )

        XCTAssertEqual(presentation.phase, .listening)
        XCTAssertEqual(presentation.title, "Listening")
        XCTAssertEqual(presentation.guidance, "Release shortcut to paste")
        XCTAssertEqual(presentation.elapsedText, "0:05")
        XCTAssertEqual(presentation.meterLevels.count, 10)
        XCTAssertTrue(presentation.meterLevels.allSatisfy { $0 >= 0 && $0 <= 1 })
        XCTAssertTrue(presentation.accessibilityLabel.contains("Release shortcut to paste"))
    }

    func testRecordingFeedbackPresentationShowsQuietToggleGuidanceAfterVoiceWasDetected() {
        let presentation = RecordingFeedbackPresentationUseCase().presentation(
            level: 0.01,
            hasDetectedVoice: true,
            elapsedSeconds: 67.9,
            triggerMode: .toggleRecording
        )

        XCTAssertEqual(presentation.phase, .quiet)
        XCTAssertEqual(presentation.title, "Quiet")
        XCTAssertEqual(presentation.guidance, "Press shortcut again to paste")
        XCTAssertEqual(presentation.elapsedText, "1:07")
        XCTAssertTrue(presentation.accessibilityLabel.contains("Press shortcut again to paste"))
    }

    func testDictionaryEntryLoadingCombinesSeedAndContextualEntries() throws {
        let useCase = DictionaryEntryLoadingUseCase(
            seedEntries: [
                DictionaryEntry(spokenForms: ["こーでっくす"], canonical: "Codex", kind: .toolName, scope: .global, confidence: 0.95, autoApply: true)
            ],
            contextualEntries: [
                DictionaryEntry(spokenForms: ["めいん"], canonical: "main", kind: .projectTerm, scope: .repository, confidence: 0.7, autoApply: true)
            ]
        )

        let entries = try useCase.loadEntries()
        let normalized = PromptNormalizationUseCase(entries: entries).normalize(rawText: "こーでっくすでめいんを確認")

        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(normalized.correctedText.contains("Codex"))
        XCTAssertTrue(normalized.correctedText.contains("main"))
    }

    func testDictionaryEntryLoadingIncludesSavedLocalContextModelEntries() throws {
        let modelEntry = DictionaryEntry(
            spokenForms: ["ろーかるこんてきすと"],
            canonical: "LocalContextModel",
            recognitionHints: ["LocalContextModel", "ローカルコンテキストモデル"],
            kind: .projectTerm,
            scope: .user,
            confidence: 0.88,
            autoApply: true
        )
        let useCase = DictionaryEntryLoadingUseCase(
            localContextModelRepository: InMemoryLocalContextModelRepository(
                model: LocalContextModel(entries: [modelEntry])
            ),
            seedEntries: []
        )

        let entries = try useCase.loadEntries()
        let normalized = PromptNormalizationUseCase(entries: entries).normalize(rawText: "ろーかるこんてきすとを読み込む")

        XCTAssertEqual(entries, [modelEntry])
        XCTAssertTrue(normalized.correctedText.contains("LocalContextModel"))
    }

    func testDictionaryEntryLoadingDeduplicatesSeedAndSavedLocalContextModelEntries() throws {
        let seedEntry = DictionaryEntry(
            spokenForms: ["ぼいすえーじぇんと"],
            canonical: "VoiceAgentInput",
            recognitionHints: ["VoiceAgentInput"],
            kind: .projectTerm,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let duplicateModelEntry = DictionaryEntry(
            spokenForms: ["ぼいすえーじぇんと"],
            canonical: "VoiceAgentInput",
            recognitionHints: ["VoiceAgentInput", "ボイスエージェント"],
            kind: .projectTerm,
            scope: .user,
            confidence: 0.7,
            autoApply: true
        )
        let useCase = DictionaryEntryLoadingUseCase(
            localContextModelRepository: InMemoryLocalContextModelRepository(
                model: LocalContextModel(entries: [duplicateModelEntry])
            ),
            seedEntries: [seedEntry]
        )

        let entries = try useCase.loadEntries()

        XCTAssertEqual(entries, [seedEntry])
    }

    func testRuntimeDictionaryLoadingDefaultsToSeedEntriesOnly() throws {
        let useCase = DictionaryEntryLoadingUseCase()

        let entries = try useCase.loadEntries()

        XCTAssertTrue(entries.contains { $0.canonical == "Codex" && $0.scope == .global })
        XCTAssertFalse(entries.contains { $0.scope == .repository })
    }

    func testLearningModeCanCombineAgentHistoryAndRepositoryVocabularySources() throws {
        let historyProvider = StubAgentHistoryTextProvider(texts: [
            "SwiftUI renders JSON previews.",
            "SwiftUI loads JSON fixtures."
        ])
        let repositorySource = RepositoryVocabularyLearningSource(
            startingURL: URL(fileURLWithPath: "/tmp/VoiceAgentInput"),
            repositoryContextProvider: StubRepositoryContextProvider(
                context: RepositoryContext(rootPath: "/tmp/VoiceAgentInput", branchName: "feature/context")
            ),
            repositoryVocabularyFilePathProvider: StubRepositoryVocabularyFilePathProvider(filePaths: [])
        )

        let result = try AgentHistoryLearningModeUseCase(
            learningSources: [historyProvider, repositorySource],
            contextCandidateGenerationUseCase: LocalContextCandidateGenerationUseCase(minimumOccurrences: 2)
        ).generateCandidates()

        XCTAssertEqual(result.scannedTextCount, 3)
        XCTAssertTrue(result.candidates.contains { $0.correctedPhrase == "SwiftUI" })
        XCTAssertTrue(result.candidates.contains {
            $0.correctedPhrase == "VoiceAgentInput" &&
            $0.rawPhrase == "voice agent input" &&
            $0.suggestedScope == .user
        })
    }

    func testDictionaryContextLoadingUseCaseKeepsRepositoryVocabularyOutOfRuntimeEntries() throws {
        let useCase = DictionaryContextLoadingUseCase(
            repositoryContextProvider: StubRepositoryContextProvider(context: RepositoryContext(rootPath: "/tmp/voice", branchName: "feature/pipeline")),
            repositoryVocabularyFilePathProvider: StubRepositoryVocabularyFilePathProvider(filePaths: ["Package.swift"])
        )

        let entries = try useCase.loadEntries(startingAt: URL(fileURLWithPath: "/tmp/voice"))

        XCTAssertTrue(entries.contains { $0.canonical == "Codex" && $0.scope == .global })
        XCTAssertFalse(entries.contains { $0.scope == .repository })
    }

    func testGitRepositoryContextProviderReadsRootAndBranch() throws {
        let runner = MockCommandRunner(outputs: [
            "/Users/tasuku/work/github.com/tasuku43/voice\n",
            "main\n"
        ])
        let provider = GitRepositoryContextProvider(commandRunner: runner)

        let context = try provider.currentContext(startingAt: URL(fileURLWithPath: "/tmp/inside-repo"))

        XCTAssertEqual(context, RepositoryContext(
            rootPath: "/Users/tasuku/work/github.com/tasuku43/voice",
            branchName: "main"
        ))
        XCTAssertEqual(runner.invocations.count, 2)
        XCTAssertEqual(runner.invocations[0].arguments, ["-C", "/tmp/inside-repo", "rev-parse", "--show-toplevel"])
        XCTAssertEqual(runner.invocations[1].arguments, ["-C", "/Users/tasuku/work/github.com/tasuku43/voice", "branch", "--show-current"])
    }

    func testGitRepositoryContextProviderReadsBoundedTrackedVocabularyFiles() throws {
        let runner = MockCommandRunner(outputs: [
            "Package.swift\nSources/App/main.swift\n.build/debug.yaml\nREADME.md\nimage.png\n"
        ])
        let provider = GitRepositoryContextProvider(
            commandRunner: runner,
            maximumVocabularyFiles: 2,
            allowedVocabularyExtensions: ["swift", "md"]
        )

        let filePaths = try provider.trackedVocabularyFilePaths(rootPath: "/repo")

        XCTAssertEqual(filePaths, ["Package.swift", "Sources/App/main.swift"])
        XCTAssertEqual(runner.invocations.count, 1)
        XCTAssertEqual(runner.invocations[0].executable, "/usr/bin/git")
        XCTAssertEqual(runner.invocations[0].arguments, ["-C", "/repo", "ls-files"])
    }

    func testProcessCommandRunnerRejectsNonGitExecutable() throws {
        let runner = ProcessCommandRunner()

        XCTAssertThrowsError(try runner.run(executable: "/usr/bin/curl", arguments: ["https://example.com"])) { error in
            XCTAssertEqual(error as? GitRepositoryContextError, .disallowedCommand("/usr/bin/curl"))
        }
    }

    func testProcessCommandRunnerRejectsNetworkCapableGitSubcommands() throws {
        let runner = ProcessCommandRunner()

        XCTAssertThrowsError(try runner.run(executable: "/usr/bin/git", arguments: ["-C", "/repo", "fetch"])) { error in
            XCTAssertEqual(error as? GitRepositoryContextError, .disallowedCommand("-C /repo fetch"))
        }
        XCTAssertThrowsError(try runner.run(executable: "/usr/bin/git", arguments: ["-C", "/repo", "pull"])) { error in
            XCTAssertEqual(error as? GitRepositoryContextError, .disallowedCommand("-C /repo pull"))
        }
        XCTAssertThrowsError(try runner.run(executable: "/usr/bin/git", arguments: ["-C", "/repo", "clone"])) { error in
            XCTAssertEqual(error as? GitRepositoryContextError, .disallowedCommand("-C /repo clone"))
        }
    }

    func testRepositoryVocabularyEntriesUseRepositoryScope() {
        let context = RepositoryContext(
            rootPath: "/Users/tasuku/work/github.com/tasuku43/voice",
            branchName: "feature/context"
        )

        let entries = RepositoryVocabularyUseCase().entries(
            from: context,
            filePaths: ["Package.swift", "docs/README.md", "Sources/Package.swift"]
        )

        XCTAssertTrue(entries.contains { $0.canonical == "voice" && $0.scope == .repository && $0.autoApply })
        XCTAssertTrue(entries.contains { $0.canonical == "feature/context" && $0.scope == .repository && $0.autoApply })
        XCTAssertTrue(entries.contains { $0.canonical == "Package.swift" && $0.scope == .repository && $0.autoApply })
        XCTAssertTrue(entries.contains { $0.canonical == "README.md" && $0.scope == .repository && $0.autoApply })
        XCTAssertEqual(entries.filter { $0.canonical == "Package.swift" }.count, 1)
    }

    @MainActor
    func testKeyboardShortcutMonitorStoresConfiguredShortcutAndTrigger() {
        let monitor = MockKeyboardShortcutMonitor()
        var triggerCount = 0
        var releaseCount = 0

        monitor.start(
            shortcut: .defaultVoiceInput,
            onTrigger: {
                triggerCount += 1
            },
            onRelease: {
                releaseCount += 1
            }
        )
        monitor.trigger()
        monitor.release()
        monitor.stop()
        monitor.trigger()
        monitor.release()

        XCTAssertEqual(triggerCount, 1)
        XCTAssertEqual(releaseCount, 1)
        XCTAssertNil(monitor.shortcut)
    }
}

private final class InMemoryLocalContextModelRepository: LocalContextModelRepository {
    private var model: LocalContextModel

    init(model: LocalContextModel = LocalContextModel()) {
        self.model = model
    }

    func loadModel() throws -> LocalContextModel {
        model
    }

    func saveModel(_ model: LocalContextModel) throws {
        self.model = model
    }
}

private final class InMemoryAppSettingsRepository: AppSettingsRepository {
    private var settings: AppSettings

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
    }

    func loadSettings() throws -> AppSettings {
        settings
    }

    func saveSettings(_ settings: AppSettings) throws {
        self.settings = settings
    }
}

private enum TemporaryRecordedAudioFileStoreTestError: Error, Equatable {
    case expected
}

private final class RecordedAudioCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: RecordedAudio?

    var value: RecordedAudio? {
        lock.lock()
        defer { lock.unlock() }
        return storedValue
    }

    func store(_ audio: RecordedAudio) {
        lock.lock()
        storedValue = audio
        lock.unlock()
    }
}

private struct SuffixPromptRefiner: PromptRefiner {
    var suffix: String

    func refine(_ prompt: NormalizedPrompt) async throws -> RefinedPrompt {
        RefinedPrompt(
            normalizedText: prompt.normalizedText,
            refinedText: prompt.normalizedText + suffix,
            changes: [
                PromptRefinementChange(
                    before: prompt.normalizedText,
                    after: prompt.normalizedText + suffix,
                    reason: "test suffix"
                )
            ]
        )
    }
}

private struct StubRepositoryContextProvider: RepositoryContextProvider {
    var context: RepositoryContext?

    func currentContext(startingAt path: URL) throws -> RepositoryContext? {
        context
    }
}

private struct StubRepositoryVocabularyFilePathProvider: RepositoryVocabularyFilePathProvider {
    var filePaths: [String]

    func trackedVocabularyFilePaths(rootPath: String) throws -> [String] {
        filePaths
    }
}

private struct StubAgentHistoryTextProvider: AgentHistoryTextProvider {
    var texts: [String]

    func historyTexts() throws -> [String] {
        texts
    }
}
