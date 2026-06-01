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

    func testPreviewRequiresExplicitConfirmationBeforeInsertion() {
        let useCase = PromptPreviewUseCase(entries: SeedDictionaries.codingAgentEntries)
        let preview = useCase.preview(rawTranscript: "くらのコードでタイプスクリプトエラーを直して")

        XCTAssertEqual(preview.rawTranscript, "くらのコードでタイプスクリプトエラーを直して")
        XCTAssertTrue(preview.correctedPrompt.contains("Claude Code"))
        XCTAssertTrue(preview.correctedPrompt.contains("TypeScript"))
        XCTAssertTrue(preview.requiresExplicitConfirmation)

        let confirmed = useCase.confirm(preview: preview)
        XCTAssertEqual(confirmed.promptToInsert, preview.correctedPrompt)
        XCTAssertFalse(confirmed.shouldSubmitAutomatically)
    }

    func testVoiceInputModeDecisionKeepsQuickPasteOffTheLearningPath() {
        let preview = PromptPreview(
            rawTranscript: "コーデックスで直して",
            correctedPrompt: "Codex で直して",
            corrections: []
        )

        let decision = VoiceInputModeDecisionUseCase().decide(mode: .quickPaste, preview: preview)

        XCTAssertEqual(decision, .quickPaste(ConfirmedPrompt(
            promptToInsert: "Codex で直して",
            candidates: []
        )))
    }

    func testVoiceInputModeDecisionUsesLearningPreviewForDictionaryGrowth() {
        let preview = PromptPreview(
            rawTranscript: "コーデックスで直して",
            correctedPrompt: "Codex で直して",
            corrections: []
        )

        let decision = VoiceInputModeDecisionUseCase().decide(mode: .learningPreview, preview: preview)

        XCTAssertEqual(decision, .learningPreview(preview))
    }

    func testVoiceInputFlowTranscribesThroughReplaceableEngineBeforePreview() async throws {
        let speechEngine = MockSpeechEngine()
        let useCase = VoiceInputFlowUseCase(
            speechEngine: speechEngine,
            entries: SeedDictionaries.codingAgentEntries
        )

        let preview = try await useCase.transcribeAndPreview(mockAudioText: "こーでっくすでブランチを確認して")

        XCTAssertEqual(preview.rawTranscript, "こーでっくすでブランチを確認して")
        XCTAssertTrue(preview.correctedPrompt.contains("Codex"))
        XCTAssertTrue(preview.correctedPrompt.contains("branch"))
        XCTAssertTrue(preview.requiresExplicitConfirmation)
    }

    func testVoiceInputFlowRecordsAudioBeforeTranscriptionAndPreview() async throws {
        let recorder = MockAudioRecorder(mockText: "くらのコードでタイプスクリプトを確認して")
        let permissionProvider = MockMicrophonePermissionProvider(status: .authorized)
        let speechEngine = MockSpeechEngine()
        let useCase = VoiceInputFlowUseCase(
            audioRecorder: recorder,
            microphonePermissionProvider: permissionProvider,
            speechEngine: speechEngine,
            entries: SeedDictionaries.codingAgentEntries
        )

        let preview = try await useCase.recordTranscribeAndPreview()

        XCTAssertEqual(preview.rawTranscript, "くらのコードでタイプスクリプトを確認して")
        XCTAssertTrue(preview.correctedPrompt.contains("Claude Code"))
        XCTAssertTrue(preview.correctedPrompt.contains("TypeScript"))
        XCTAssertEqual(permissionProvider.requestAccessCallCount, 0)
    }

    func testVoiceInputFlowReportsRecordedAudioForDebugObservability() async throws {
        let audio = RecordedAudio(
            data: Data("くらのコードでタイプスクリプトを確認して".utf8),
            formatDescription: "mock-text",
            durationSeconds: 4.2
        )
        let capturedAudio = RecordedAudioCapture()
        let useCase = VoiceInputFlowUseCase(
            audioRecorder: MockAudioRecorder(audio: audio),
            microphonePermissionProvider: MockMicrophonePermissionProvider(status: .authorized),
            speechEngine: MockSpeechEngine(),
            entries: SeedDictionaries.codingAgentEntries,
            recordedAudioHandler: { capturedAudio.store($0) }
        )

        _ = try await useCase.recordTranscribeAndPreview()

        XCTAssertEqual(capturedAudio.value, audio)
    }

    func testVoiceInputPipelineKeepsTranscriptNormalizationRefinementAndPreviewStages() async throws {
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
        XCTAssertEqual(result.preview.rawTranscript, result.transcript.text)
        XCTAssertEqual(result.preview.correctedPrompt, result.refinedPrompt.refinedText)
        XCTAssertTrue(result.preview.requiresExplicitConfirmation)
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

        let refined = try await JapanesePunctuationPromptRefiner().refine(
            normalized,
            instruction: RefinementInstruction()
        )

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
        XCTAssertEqual(result.preview.correctedPrompt, result.refinedPrompt.refinedText)
    }

    func testNoOpPromptRefinerPreservesNormalizedPrompt() async throws {
        let normalized = NormalizedPrompt(
            rawText: "こーでっくす",
            normalizedText: "Codex",
            corrections: []
        )

        let refined = try await NoOpPromptRefiner().refine(normalized, instruction: RefinementInstruction())

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

        let refined = try await JapanesePunctuationPromptRefiner().refine(
            normalized,
            instruction: RefinementInstruction()
        )

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

    func testAgentHistoryDictionaryLearningFindsRepeatedDeveloperTerms() {
        let texts = [
            "Fix the SwiftUI preview and call the API from Codex.",
            "The SwiftUI view should not block the API call.",
            "Codex should preserve the JSON payload.",
            "ProjectSpecificName appears more than once.",
            "ProjectSpecificName appears again."
        ]

        let candidates = AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
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
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
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
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
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
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
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
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
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
        let approvedEntry = DictionaryEntry(
            spokenForms: ["ぷろじぇくとぼいす"],
            canonical: "ProjectVoice",
            recognitionHints: ["ProjectVoice", "プロジェクトボイス"],
            kind: .projectTerm,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let learningResult = AgentHistoryLearningModeResult(
            scannedTextCount: 2,
            sourceTextCounts: ["agentHistory": 2],
            candidates: [
                CorrectionCandidate(
                    rawPhrase: "すいふとゆーあい",
                    correctedPhrase: "SwiftUI",
                    confidence: 0.8,
                    occurrenceCount: 2,
                    reason: "Found 2 uses in local agent history.",
                    suggestedScope: .user,
                    autoApplyAllowed: true
                )
            ]
        )

        let model = LocalContextModelBuildUseCase(
            seedEntries: [],
            approvedEntries: [approvedEntry]
        ).build(learningResult: learningResult, rebuiltAt: Date(timeIntervalSince1970: 1_800))

        XCTAssertEqual(model.sourceTextCounts["agentHistory"], 2)
        XCTAssertEqual(model.sourceKinds, ["agentHistory"])
        XCTAssertEqual(model.lastRebuiltAt, Date(timeIntervalSince1970: 1_800))
        XCTAssertEqual(model.generatedCandidateCount, 1)
        XCTAssertEqual(model.postSTTEntries.map(\.canonical), ["ProjectVoice", "SwiftUI"])
        XCTAssertEqual(
            model.recognitionHints().contextualStrings,
            ["ProjectVoice", "プロジェクトボイス", "SwiftUI", "すいふとゆーあい"]
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
                    reason: "Found in local agent history.",
                    suggestedScope: .user,
                    autoApplyAllowed: true
                )
            ]
        )

        let model = LocalContextModelBuildUseCase(seedEntries: [], approvedEntries: [])
            .build(learningResult: learningResult, includeGeneratedCandidates: false)

        XCTAssertTrue(model.postSTTEntries.isEmpty)
        XCTAssertTrue(model.recognitionHints().contextualStrings.isEmpty)
        XCTAssertEqual(model.generatedCandidateCount, 1)
        XCTAssertEqual(model.sourceTextCounts["agentHistory"], 1)
    }

    func testLocalContextModelDataUseCaseRebuildsAndPersistsModel() throws {
        let approvedEntry = DictionaryEntry(
            spokenForms: ["ぼいす"],
            canonical: "VoiceAgentInput",
            recognitionHints: ["VoiceAgentInput"],
            kind: .projectTerm,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
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
            buildUseCase: LocalContextModelBuildUseCase(seedEntries: [], approvedEntries: [approvedEntry])
        ).rebuildModel(learningResult: learningResult, rebuiltAt: Date(timeIntervalSince1970: 2_400))

        XCTAssertEqual(model.postSTTEntries.map(\.canonical), ["VoiceAgentInput", "main"])
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

    func testVoiceInputFlowRequestsMicrophonePermissionWhenNeeded() async throws {
        let permissionProvider = MockMicrophonePermissionProvider(status: .notDetermined, requestedStatus: .authorized)
        let useCase = VoiceInputFlowUseCase(
            audioRecorder: MockAudioRecorder(mockText: "こーでっくすでブランチを確認して"),
            microphonePermissionProvider: permissionProvider,
            speechEngine: MockSpeechEngine(),
            entries: SeedDictionaries.codingAgentEntries
        )

        let preview = try await useCase.recordTranscribeAndPreview()

        XCTAssertTrue(preview.correctedPrompt.contains("Codex"))
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

    func testVoiceInputFlowDoesNotRecordWhenMicrophonePermissionIsDenied() async {
        let permissionProvider = MockMicrophonePermissionProvider(status: .denied)
        let useCase = VoiceInputFlowUseCase(
            audioRecorder: MockAudioRecorder(mockText: "recording should not be consumed"),
            microphonePermissionProvider: permissionProvider,
            speechEngine: MockSpeechEngine(),
            entries: SeedDictionaries.codingAgentEntries
        )

        do {
            _ = try await useCase.recordTranscribeAndPreview()
            XCTFail("Expected microphone permission denial")
        } catch {
            XCTAssertEqual(error as? VoiceInputFlowError, .microphonePermissionDenied(status: .denied))
            XCTAssertEqual(permissionProvider.requestAccessCallCount, 0)
        }
    }

    func testVoiceInputFlowRequiresRecorderForRecordPath() async {
        let useCase = VoiceInputFlowUseCase(
            speechEngine: MockSpeechEngine(),
            entries: SeedDictionaries.codingAgentEntries
        )

        do {
            _ = try await useCase.recordTranscribeAndPreview()
            XCTFail("Expected recorder unavailable error")
        } catch {
            XCTAssertEqual(error as? VoiceInputFlowError, .audioRecorderUnavailable)
        }
    }

    func testConfirmingEditedPromptExtractsLearningCandidates() {
        let useCase = PromptPreviewUseCase(entries: [])
        let preview = useCase.preview(rawTranscript: "くらのコードでタイプスクリプトエラーを直して")
        let confirmed = useCase.confirm(
            preview: preview,
            finalEditedPrompt: "Claude Code で TypeScript error を直して"
        )

        XCTAssertEqual(confirmed.promptToInsert, "Claude Code で TypeScript error を直して")
        XCTAssertTrue(confirmed.candidates.contains { $0.rawPhrase == "くらのコード" && $0.correctedPhrase == "Claude Code" })
        XCTAssertTrue(confirmed.candidates.contains { $0.rawPhrase == "タイプスクリプト" && $0.correctedPhrase == "TypeScript" })
        XCTAssertFalse(confirmed.shouldSubmitAutomatically)
    }

    func testPromptEditLearningCanReviewCandidatesOffTheTranscriptionPath() async throws {
        let previewUseCase = PromptPreviewUseCase(entries: [])
        let preview = previewUseCase.preview(rawTranscript: "コーデックスで直して")
        let confirmed = try await PromptEditLearningUseCase(
            previewUseCase: previewUseCase,
            candidateReviewer: StubLearningCandidateReviewer { candidates, _ in
                candidates.map { candidate in
                    var reviewed = candidate
                    reviewed.confidence = 0.93
                    reviewed.reason = "Reviewed after user confirmation by an off-path detector."
                    return reviewed
                }
            }
        ).confirm(
            preview: preview,
            finalEditedPrompt: "Codex で直して"
        )

        let codex = try XCTUnwrap(confirmed.candidates.first { $0.correctedPhrase == "Codex" })
        XCTAssertEqual(confirmed.promptToInsert, "Codex で直して")
        XCTAssertEqual(codex.confidence, 0.93)
        XCTAssertEqual(codex.reason, "Reviewed after user confirmation by an off-path detector.")
        XCTAssertFalse(confirmed.shouldSubmitAutomatically)
    }

    func testPromptEditLearningUsesRepositoryScopeWhenConfigured() async throws {
        let previewUseCase = PromptPreviewUseCase(entries: [])
        let preview = previewUseCase.preview(rawTranscript: "ボイスエージェントインプットを直して")
        let confirmed = try await PromptEditLearningUseCase(
            previewUseCase: previewUseCase
        ).confirm(
            preview: preview,
            finalEditedPrompt: "VoiceAgentInput を直して",
            suggestedScope: .repository
        )

        let candidate = try XCTUnwrap(confirmed.candidates.first {
            $0.rawPhrase == "ボイスエージェントインプット"
                && $0.correctedPhrase == "VoiceAgentInput"
        })
        XCTAssertEqual(candidate.suggestedScope, .repository)
        XCTAssertTrue(candidate.autoApplyAllowed)
    }

    func testPromptEditLearningFallsBackToUnreviewedCandidatesWhenReviewerFails() async throws {
        let previewUseCase = PromptPreviewUseCase(entries: [])
        let preview = previewUseCase.preview(rawTranscript: "コーデックスで直して")
        let confirmed = try await PromptEditLearningUseCase(
            previewUseCase: previewUseCase,
            candidateReviewer: StubLearningCandidateReviewer { _, _ in
                throw PromptEditLearningTestError.reviewerFailed
            }
        ).confirm(
            preview: preview,
            finalEditedPrompt: "Codex で直して"
        )

        let codex = try XCTUnwrap(confirmed.candidates.first { $0.correctedPhrase == "Codex" })
        XCTAssertEqual(confirmed.promptToInsert, "Codex で直して")
        XCTAssertEqual(codex.rawPhrase, "コーデックス")
        XCTAssertFalse(confirmed.shouldSubmitAutomatically)
    }

    func testDetectorBackedLearningReviewerPreservesDangerousCandidateGuardrails() async throws {
        let diff = PromptDiff(
            rawText: "アールエムを使って消して",
            autoCorrectedText: "アールエムを使って消して",
            finalEditedText: "rm を使って消して"
        )
        let reviewed = try await DetectorBackedLearningCandidateReviewer(
            detector: FixedVoiceMisrecognitionDetector(
                evidence: VoiceMisrecognitionEvidence(confidence: 0.99, reason: "High confidence detector result.")
            )
        ).review(
            candidates: [
                CorrectionCandidate(
                    rawPhrase: "アールエム",
                    correctedPhrase: "rm",
                    confidence: 0.3,
                    suggestedScope: .user,
                    dangerous: true,
                    autoApplyAllowed: true
                )
            ],
            diff: diff
        )

        XCTAssertEqual(reviewed[0].confidence, 0.4)
        XCTAssertEqual(reviewed[0].reason, "High confidence detector result.")
        XCTAssertFalse(reviewed[0].autoApplyAllowed)
    }

    func testApprovedCandidatesPersistAsLocalDictionaryEntries() throws {
        let repository = InMemoryDictionaryRepository()
        let useCase = DictionaryLearningUseCase(
            repository: repository,
            now: { Date(timeIntervalSince1970: 1_234) }
        )
        let candidates = [
            CorrectionCandidate(rawPhrase: "くらのコード", correctedPhrase: "Claude Code", confidence: 0.72, suggestedScope: .user, approved: true, autoApplyAllowed: true),
            CorrectionCandidate(rawPhrase: "アールエム", correctedPhrase: "rm", confidence: 0.4, suggestedScope: .user, approved: true, dangerous: true, autoApplyAllowed: true),
            CorrectionCandidate(rawPhrase: "却下", correctedPhrase: "reject me", confidence: 0.9, suggestedScope: .user, rejected: true, autoApplyAllowed: true)
        ]

        let approved = try useCase.approveCandidates(candidates)
        let saved = try repository.loadEntries()

        XCTAssertEqual(approved.count, 2)
        XCTAssertEqual(saved.count, 2)
        XCTAssertTrue(saved.contains {
            $0.spokenForms == ["くらのコード"] &&
                $0.canonical == "Claude Code" &&
                $0.recognitionHints.contains("Claude Code") &&
                !$0.recognitionHints.contains("くらのコード") &&
                $0.autoApply
        })
        XCTAssertTrue(saved.contains {
            $0.spokenForms == ["アールエム"] &&
                $0.canonical == "rm" &&
                $0.recognitionHints == ["rm"] &&
                !$0.autoApply
        })
        XCTAssertFalse(saved.contains { $0.canonical == "reject me" })
    }

    func testUnapprovedCandidatesDoNotPersist() throws {
        let repository = InMemoryDictionaryRepository()
        let useCase = DictionaryLearningUseCase(repository: repository)

        let approved = try useCase.approveCandidates([
            CorrectionCandidate(rawPhrase: "候補", correctedPhrase: "candidate", confidence: 0.8, suggestedScope: .user)
        ])

        XCTAssertEqual(approved, [])
        XCTAssertEqual(try repository.loadEntries(), [])
    }

    func testApprovingEquivalentCandidateStrengthensExistingDictionaryEntry() throws {
        let existingEntry = DictionaryEntry(
            spokenForms: ["すいふとゆーあい"],
            canonical: "SwiftUI",
            kind: .phrase,
            scope: .user,
            confidence: 0.55,
            autoApply: false,
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        let repository = InMemoryDictionaryRepository(entries: [existingEntry])

        _ = try DictionaryLearningUseCase(
            repository: repository,
            now: { Date(timeIntervalSince1970: 20) }
        ).approveCandidates([
            CorrectionCandidate(
                rawPhrase: "すいふとゆーあい",
                correctedPhrase: "SwiftUI",
                confidence: 0.82,
                suggestedScope: .user,
                approved: true,
                autoApplyAllowed: true
            )
        ])
        let saved = try repository.loadEntries()

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].confidence, 0.82)
        XCTAssertTrue(saved[0].autoApply)
        XCTAssertEqual(saved[0].createdAt, Date(timeIntervalSince1970: 10))
        XCTAssertEqual(saved[0].updatedAt, Date(timeIntervalSince1970: 20))
    }

    func testCandidateApprovalMarksSelectedOnly() {
        let candidates = [
            CorrectionCandidate(rawPhrase: "one", correctedPhrase: "1", confidence: 0.8, suggestedScope: .user),
            CorrectionCandidate(rawPhrase: "two", correctedPhrase: "2", confidence: 0.8, suggestedScope: .user)
        ]

        let approved = CandidateApprovalUseCase().approveCandidates(candidates, selectedIndexes: [1])

        XCTAssertTrue(approved[0].rejected)
        XCTAssertFalse(approved[0].approved)
        XCTAssertTrue(approved[1].approved)
        XCTAssertFalse(approved[1].rejected)
    }

    func testLearningApprovalUseCasePersistsOnlySelectedCandidates() throws {
        let repository = InMemoryDictionaryRepository()
        let candidates = [
            CorrectionCandidate(rawPhrase: "くらのコード", correctedPhrase: "Claude Code", confidence: 0.8, suggestedScope: .user),
            CorrectionCandidate(rawPhrase: "却下", correctedPhrase: "reject me", confidence: 0.8, suggestedScope: .user)
        ]

        let approved = try LearningApprovalUseCase(
            repository: repository,
            now: { Date(timeIntervalSince1970: 42) }
        ).approveSelectedCandidates(candidates, selectedIndexes: [0])

        XCTAssertEqual(approved.map(\.canonical), ["Claude Code"])
        XCTAssertEqual(try repository.loadEntries().map(\.canonical), ["Claude Code"])
    }

    func testApprovedLearningEntriesAffectNextRuleBasedNormalization() throws {
        let repository = InMemoryDictionaryRepository()
        let candidates = [
            CorrectionCandidate(
                rawPhrase: "すいふとゆーあい",
                correctedPhrase: "SwiftUI",
                confidence: 0.8,
                suggestedScope: .user,
                autoApplyAllowed: true
            )
        ]

        _ = try LearningApprovalUseCase(repository: repository)
            .approveSelectedCandidates(candidates, selectedIndexes: [0])
        let entries = try DictionaryEntryLoadingUseCase(
            repository: repository,
            seedEntries: [],
            contextualEntries: []
        ).loadEntries()
        let preview = PromptPreviewUseCase(entries: entries)
            .preview(rawTranscript: "すいふとゆーあいのpreviewを直して")
        var foundLearnedCorrection = false
        for correction in preview.corrections {
            if correction.original == "すいふとゆーあい",
               correction.replacement == "SwiftUI ",
               correction.canonical == "SwiftUI" {
                foundLearnedCorrection = true
            }
        }

        XCTAssertEqual(preview.correctedPrompt, "SwiftUI のpreviewを直して")
        XCTAssertTrue(foundLearnedCorrection)
    }

    func testAgentHistoryLearningApprovalEvolvesRuleBasedNormalizationForProjectTerms() throws {
        let repository = InMemoryDictionaryRepository()
        let historyProvider = StubAgentHistoryTextProvider(texts: [
            "ProjectSpecificName appears in this repository prompt.",
            "Please preserve ProjectSpecificName when editing docs."
        ])
        let learningResult = try AgentHistoryLearningModeUseCase(
            historyProvider: historyProvider,
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
        ).generateCandidates(existingEntries: try repository.loadEntries())

        guard let index = learningResult.candidates.firstIndex(where: {
            $0.rawPhrase == "project specific name" &&
                $0.correctedPhrase == "ProjectSpecificName"
        }) else {
            return XCTFail("Expected ProjectSpecificName learning candidate")
        }

        _ = try LearningApprovalUseCase(repository: repository)
            .approveSelectedCandidates(learningResult.candidates, selectedIndexes: [index])
        let entries = try DictionaryEntryLoadingUseCase(
            repository: repository,
            seedEntries: [],
            contextualEntries: []
        ).loadEntries()
        let preview = PromptPreviewUseCase(entries: entries)
            .preview(rawTranscript: "project specific nameの設定を直して")

        XCTAssertEqual(preview.correctedPrompt, "ProjectSpecificName の設定を直して")
    }

    func testPromptInsertionRequiresExplicitConfirmation() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let confirmed = ConfirmedPrompt(promptToInsert: "Claude Code で確認して", candidates: [])

        XCTAssertThrowsError(try useCase.insert(confirmed, explicitConfirmation: false)) { error in
            XCTAssertEqual(error as? PromptInsertionError, .explicitConfirmationRequired)
        }
        XCTAssertTrue(insertionController.insertedRequests.isEmpty)
    }

    func testPromptInsertionUsesPromptTextWithoutSubmitting() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let confirmed = ConfirmedPrompt(
            promptToInsert: "Claude Code で確認して",
            candidates: [
                CorrectionCandidate(rawPhrase: "くらのコード", correctedPhrase: "Claude Code", confidence: 0.72, suggestedScope: .user, autoApplyAllowed: true)
            ]
        )

        try useCase.insert(confirmed, explicitConfirmation: true)

        XCTAssertEqual(insertionController.insertedRequests, [
            TextInsertionRequest(text: "Claude Code で確認して", submitAutomatically: false)
        ])
    }

    func testPromptInsertionRejectsAutomaticSubmitEvenIfRequestedByCaller() throws {
        let insertionController = MockTextInsertionController()
        let useCase = PromptInsertionUseCase(insertionController: insertionController)
        let confirmed = ConfirmedPrompt(
            promptToInsert: "Claude Code で確認して",
            candidates: [],
            shouldSubmitAutomatically: true
        )

        XCTAssertThrowsError(try useCase.insert(confirmed, explicitConfirmation: true)) { error in
            XCTAssertEqual(error as? PromptInsertionError, .automaticSubmitRejected)
        }
        XCTAssertTrue(insertionController.insertedRequests.isEmpty)
    }

    func testLocalLearningDataExportImportAndDeleteAll() throws {
        let existingEntry = DictionaryEntry(
            spokenForms: ["くらのコード"],
            canonical: "Claude Code",
            kind: .toolName,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let importedEntry = DictionaryEntry(
            spokenForms: ["りぽ"],
            canonical: "repo",
            kind: .projectTerm,
            scope: .user,
            confidence: 0.8,
            autoApply: true
        )
        let repository = InMemoryDictionaryRepository(entries: [existingEntry])
        let useCase = LocalLearningDataUseCase(repository: repository)

        XCTAssertEqual(try useCase.exportApprovedEntries(), [existingEntry])

        try useCase.importApprovedEntries([existingEntry, importedEntry])
        XCTAssertEqual(try repository.loadEntries(), [existingEntry, importedEntry])

        try useCase.deleteAllLocalLearningData()
        XCTAssertEqual(try repository.loadEntries(), [])
    }

    func testLocalLearningDataImportCanReplaceExistingEntries() throws {
        let existingEntry = DictionaryEntry(
            spokenForms: ["くらのコード"],
            canonical: "Claude Code",
            kind: .toolName,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let replacementEntry = DictionaryEntry(
            spokenForms: ["こーでっくす"],
            canonical: "Codex",
            kind: .toolName,
            scope: .user,
            confidence: 0.85,
            autoApply: true
        )
        let repository = InMemoryDictionaryRepository(entries: [existingEntry])
        let useCase = LocalLearningDataUseCase(repository: repository)

        try useCase.importApprovedEntries([replacementEntry], merge: false)

        XCTAssertEqual(try repository.loadEntries(), [replacementEntry])
    }

    func testLocalLearningDataDocumentCodecRoundTrip() throws {
        let entries = [
            DictionaryEntry(
                spokenForms: ["くらのコード"],
                canonical: "Claude Code",
                kind: .toolName,
                scope: .user,
                confidence: 0.9,
                autoApply: true,
                createdAt: Date(timeIntervalSince1970: 1),
                updatedAt: Date(timeIntervalSince1970: 2)
            )
        ]
        let codec = LocalLearningDataDocumentCodec()

        let data = try codec.encode(entries)
        let text = String(data: data, encoding: .utf8) ?? ""
        let decoded = try codec.decode(data)

        XCTAssertTrue(text.contains("Claude Code"))
        XCTAssertTrue(text.contains("recognitionHints"))
        XCTAssertTrue(text.contains("1970-01-01T00:00:01Z"))
        XCTAssertEqual(decoded, entries)
    }

    func testLocalLearningDataDocumentCodecDecodesLegacyEntriesWithoutRecognitionHints() throws {
        let data = """
        [
          {
            "id": "00000000-0000-0000-0000-000000000001",
            "spokenForms": ["くらのコード"],
            "canonical": "Claude Code",
            "kind": "toolName",
            "scope": "user",
            "confidence": 0.9,
            "autoApply": true,
            "createdAt": "1970-01-01T00:00:01Z",
            "updatedAt": "1970-01-01T00:00:02Z"
          }
        ]
        """.data(using: .utf8)!

        let decoded = try LocalLearningDataDocumentCodec().decode(data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].spokenForms, ["くらのコード"])
        XCTAssertEqual(decoded[0].canonical, "Claude Code")
        XCTAssertTrue(decoded[0].recognitionHints.contains("Claude Code"))
        XCTAssertFalse(decoded[0].recognitionHints.contains("くらのコード"))
    }

    func testJSONDictionaryRepositoryRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent("dictionary.json")
        let repository = JSONDictionaryRepository(fileURL: fileURL)
        let entries = [DictionaryEntry(spokenForms: ["テスト"], canonical: "test", kind: .command, scope: .user, confidence: 0.9, autoApply: true)]
        try repository.saveEntries(entries)
        let loaded = try repository.loadEntries()
        XCTAssertEqual(loaded, entries)
    }

    func testLocalLearningDictionaryStoreCreatesRepositoryDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LocalLearningDictionaryStore(directoryURL: directory)
        let repository = try store.repository()
        let entries = [DictionaryEntry(spokenForms: ["くらのコード"], canonical: "Claude Code", kind: .toolName, scope: .user, confidence: 0.9, autoApply: true)]

        try repository.saveEntries(entries)

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertEqual(try repository.loadEntries(), entries)
    }

    func testJSONAppSettingsRepositoryRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LocalLearningDictionaryStore(directoryURL: directory)
        let repository = try store.settingsRepository()

        XCTAssertEqual(try repository.loadSettings(), AppSettings())

        try repository.saveSettings(AppSettings(
            repositoryPath: "/tmp/repo",
            recordingDurationSeconds: 6,
            speechLocaleIdentifier: "en-US",
            voiceInputShortcut: KeyboardShortcut(key: "s", modifiers: [.control, .shift]),
            voiceInputTriggerMode: .toggleRecording
        ))

        XCTAssertEqual(try repository.loadSettings(), AppSettings(
            repositoryPath: "/tmp/repo",
            recordingDurationSeconds: 6,
            speechLocaleIdentifier: "en-US",
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
        XCTAssertEqual(settings.voiceInputMode, .quickPaste)
        XCTAssertEqual(settings.voiceInputShortcut, .defaultVoiceInput)
        XCTAssertEqual(settings.voiceInputTriggerMode, .pressAndHold)
    }

    func testAppSettingsEffectiveValuesClampUnsafeInput() {
        let tooShort = AppSettings(recordingDurationSeconds: 0.2, speechLocaleIdentifier: "   ")
        let tooLong = AppSettings(recordingDurationSeconds: 60, speechLocaleIdentifier: " en-US ")

        XCTAssertEqual(tooShort.effectiveRecordingDurationSeconds, 1)
        XCTAssertEqual(tooShort.effectiveSpeechLocaleIdentifier, "ja-JP")
        XCTAssertEqual(tooLong.effectiveRecordingDurationSeconds, 30)
        XCTAssertEqual(tooLong.effectiveSpeechLocaleIdentifier, "en-US")
        XCTAssertEqual(AppSettings().preferredLearningScope, .user)
        XCTAssertEqual(AppSettings(repositoryPath: "/tmp/repo").preferredLearningScope, .user)
    }

    func testAppSettingsUseCaseSavesRepositoryAndClampedRecordingSettings() throws {
        let repository = InMemoryAppSettingsRepository()
        let useCase = AppSettingsUseCase(repository: repository)

        let repositorySettings = try useCase.saveRepositoryPath("/tmp/repo")
        let recordingSettings = try useCase.saveRecordingSettings(
            recordingDurationSeconds: 99,
            speechLocaleIdentifier: " en-US "
        )

        XCTAssertEqual(repositorySettings.repositoryPath, "/tmp/repo")
        XCTAssertEqual(recordingSettings.repositoryPath, "/tmp/repo")
        XCTAssertEqual(recordingSettings.recordingDurationSeconds, 30)
        XCTAssertEqual(recordingSettings.speechLocaleIdentifier, "en-US")
        XCTAssertEqual(try repository.loadSettings(), recordingSettings)

        let modeSettings = try useCase.saveVoiceInputMode(.learningPreview)
        XCTAssertEqual(modeSettings.voiceInputMode, .learningPreview)
        XCTAssertEqual(try repository.loadSettings().voiceInputMode, .learningPreview)

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

    func testDictionaryEntryLoadingCombinesSeedAndApprovedLocalEntries() throws {
        let localEntry = DictionaryEntry(
            spokenForms: ["ぷろじぇくとぼいす"],
            canonical: "voice-agent-input",
            kind: .projectTerm,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let repository = InMemoryDictionaryRepository(entries: [localEntry])
        let useCase = DictionaryEntryLoadingUseCase(
            repository: repository,
            seedEntries: [
                DictionaryEntry(spokenForms: ["こーでっくす"], canonical: "Codex", kind: .toolName, scope: .global, confidence: 0.95, autoApply: true)
            ],
            contextualEntries: [
                DictionaryEntry(spokenForms: ["めいん"], canonical: "main", kind: .projectTerm, scope: .repository, confidence: 0.7, autoApply: true)
            ]
        )

        let entries = try useCase.loadEntries()
        let preview = PromptPreviewUseCase(entries: entries).preview(rawTranscript: "こーでっくすでぷろじぇくとぼいすを確認")

        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(preview.correctedPrompt.contains("Codex"))
        XCTAssertTrue(preview.correctedPrompt.contains("voice-agent-input"))
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
            repository: InMemoryDictionaryRepository(),
            localContextModelRepository: InMemoryLocalContextModelRepository(
                model: LocalContextModel(entries: [modelEntry])
            ),
            seedEntries: []
        )

        let entries = try useCase.loadEntries()
        let preview = PromptPreviewUseCase(entries: entries).preview(rawTranscript: "ろーかるこんてきすとを読み込む")

        XCTAssertEqual(entries, [modelEntry])
        XCTAssertTrue(preview.correctedPrompt.contains("LocalContextModel"))
    }

    func testDictionaryEntryLoadingDeduplicatesSavedLocalContextModelEntries() throws {
        let approvedEntry = DictionaryEntry(
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
            repository: InMemoryDictionaryRepository(entries: [approvedEntry]),
            localContextModelRepository: InMemoryLocalContextModelRepository(
                model: LocalContextModel(entries: [duplicateModelEntry])
            ),
            seedEntries: []
        )

        let entries = try useCase.loadEntries()

        XCTAssertEqual(entries, [approvedEntry])
    }

    func testRuntimeDictionaryLoadingDefaultsToSeedAndApprovedEntriesOnly() throws {
        let localEntry = DictionaryEntry(
            spokenForms: ["ぼいすえーじぇんと"],
            canonical: "VoiceAgentInput",
            kind: .projectTerm,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let useCase = DictionaryEntryLoadingUseCase(
            repository: InMemoryDictionaryRepository(entries: [localEntry])
        )

        let entries = try useCase.loadEntries()

        XCTAssertTrue(entries.contains { $0.canonical == "VoiceAgentInput" && $0.scope == .user })
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
            dictionaryLearningUseCase: AgentHistoryDictionaryLearningUseCase(minimumOccurrences: 2)
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
        let localEntry = DictionaryEntry(
            spokenForms: ["ろーかる"],
            canonical: "local-term",
            kind: .projectTerm,
            scope: .user,
            confidence: 0.9,
            autoApply: true
        )
        let useCase = DictionaryContextLoadingUseCase(
            repository: InMemoryDictionaryRepository(entries: [localEntry]),
            repositoryContextProvider: StubRepositoryContextProvider(context: RepositoryContext(rootPath: "/tmp/voice", branchName: "feature/pipeline")),
            repositoryVocabularyFilePathProvider: StubRepositoryVocabularyFilePathProvider(filePaths: ["Package.swift"])
        )

        let entries = try useCase.loadEntries(startingAt: URL(fileURLWithPath: "/tmp/voice"))

        XCTAssertTrue(entries.contains { $0.canonical == "local-term" && $0.scope == .user })
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

    func testVoiceInputHistoryRecordsFinalPromptsOnlyAndBoundsStoredEntries() throws {
        let repository = InMemoryVoiceInputHistoryRepository()
        let useCase = VoiceInputHistoryUseCase(repository: repository, maximumEntries: 2)

        try useCase.record(prompt: " first prompt ", createdAt: Date(timeIntervalSince1970: 1))
        try useCase.record(prompt: "second prompt", createdAt: Date(timeIntervalSince1970: 2))
        try useCase.record(prompt: "first prompt", createdAt: Date(timeIntervalSince1970: 3))
        try useCase.record(prompt: "third prompt", createdAt: Date(timeIntervalSince1970: 4))
        try useCase.record(prompt: "   ", createdAt: Date(timeIntervalSince1970: 5))

        let entries = try useCase.recentEntries()

        XCTAssertEqual(entries.map(\.prompt), ["third prompt", "first prompt"])
    }

    func testJSONVoiceInputHistoryRepositoryRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LocalLearningDictionaryStore(directoryURL: directory)
        let repository = try store.voiceInputHistoryRepository()
        let entries = [
            VoiceInputHistoryEntry(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                createdAt: Date(timeIntervalSince1970: 10),
                prompt: "paste this"
            )
        ]

        try repository.saveEntries(entries)

        XCTAssertEqual(try repository.loadEntries(), entries)
        let historyURL = directory.appendingPathComponent("voice-input-history.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: historyURL.path))
        let storedJSON = try String(contentsOf: historyURL, encoding: .utf8)
        XCTAssertTrue(storedJSON.contains("\"prompt\""))
        XCTAssertFalse(storedJSON.contains("rawTranscript"))
        XCTAssertFalse(storedJSON.contains("candidates"))
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

private final class InMemoryDictionaryRepository: DictionaryRepository {
    private var entries: [DictionaryEntry]

    init(entries: [DictionaryEntry] = []) {
        self.entries = entries
    }

    func loadEntries() throws -> [DictionaryEntry] {
        entries
    }

    func saveEntries(_ entries: [DictionaryEntry]) throws {
        self.entries = entries
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

private final class InMemoryVoiceInputHistoryRepository: VoiceInputHistoryRepository {
    private var entries: [VoiceInputHistoryEntry]

    init(entries: [VoiceInputHistoryEntry] = []) {
        self.entries = entries
    }

    func loadEntries() throws -> [VoiceInputHistoryEntry] {
        entries
    }

    func saveEntries(_ entries: [VoiceInputHistoryEntry]) throws {
        self.entries = entries
    }
}

private enum TemporaryRecordedAudioFileStoreTestError: Error, Equatable {
    case expected
}

private enum PromptEditLearningTestError: Error {
    case reviewerFailed
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

    func refine(_ prompt: NormalizedPrompt, instruction: RefinementInstruction) async throws -> RefinedPrompt {
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

private struct StubLearningCandidateReviewer: LearningCandidateReviewer {
    var reviewClosure: @Sendable ([CorrectionCandidate], PromptDiff) async throws -> [CorrectionCandidate]

    init(_ reviewClosure: @escaping @Sendable ([CorrectionCandidate], PromptDiff) async throws -> [CorrectionCandidate]) {
        self.reviewClosure = reviewClosure
    }

    func review(candidates: [CorrectionCandidate], diff: PromptDiff) async throws -> [CorrectionCandidate] {
        try await reviewClosure(candidates, diff)
    }
}

private struct FixedVoiceMisrecognitionDetector: VoiceMisrecognitionDetector {
    var evidence: VoiceMisrecognitionEvidence

    func evidence(rawPhrase: String, correctedPhrase: String, diff: PromptDiff) -> VoiceMisrecognitionEvidence {
        evidence
    }
}
