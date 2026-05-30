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
            accessibilityPermissionProvider: MockAccessibilityPermissionProvider(status: .notTrusted)
        )

        XCTAssertEqual(useCase.currentStatus(), PermissionStatusSnapshot(
            microphone: .authorized,
            speechRecognition: .denied,
            accessibility: .notTrusted
        ))
    }

    func testAppleSpeechEngineRequiresOnDeviceRecognitionByDefault() {
        let engine = AppleSpeechEngine()

        XCTAssertTrue(engine.requiresOnDeviceRecognition)
        XCTAssertEqual(engine.localeIdentifier, "ja-JP")
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
        XCTAssertTrue(saved.contains { $0.spokenForms == ["くらのコード"] && $0.canonical == "Claude Code" && $0.autoApply })
        XCTAssertTrue(saved.contains { $0.spokenForms == ["アールエム"] && $0.canonical == "rm" && !$0.autoApply })
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
        XCTAssertTrue(text.contains("1970-01-01T00:00:01Z"))
        XCTAssertEqual(decoded, entries)
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
            speechLocaleIdentifier: "en-US"
        ))

        XCTAssertEqual(try repository.loadSettings(), AppSettings(
            repositoryPath: "/tmp/repo",
            recordingDurationSeconds: 6,
            speechLocaleIdentifier: "en-US"
        ))
    }

    func testJSONAppSettingsRepositoryDefaultsMissingNewFields() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent("settings.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try #"{"repositoryPath":"/tmp/repo"}"#.data(using: .utf8)!.write(to: fileURL)

        let settings = try JSONAppSettingsRepository(fileURL: fileURL).loadSettings()

        XCTAssertEqual(settings, AppSettings(repositoryPath: "/tmp/repo"))
    }

    func testAppSettingsEffectiveValuesClampUnsafeInput() {
        let tooShort = AppSettings(recordingDurationSeconds: 0.2, speechLocaleIdentifier: "   ")
        let tooLong = AppSettings(recordingDurationSeconds: 60, speechLocaleIdentifier: " en-US ")

        XCTAssertEqual(tooShort.effectiveRecordingDurationSeconds, 1)
        XCTAssertEqual(tooShort.effectiveSpeechLocaleIdentifier, "ja-JP")
        XCTAssertEqual(tooLong.effectiveRecordingDurationSeconds, 30)
        XCTAssertEqual(tooLong.effectiveSpeechLocaleIdentifier, "en-US")
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

    func testDictionaryContextLoadingUseCaseCombinesSeedLocalAndRepositoryVocabulary() throws {
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
        XCTAssertTrue(entries.contains { $0.canonical == "voice" && $0.scope == .repository })
        XCTAssertTrue(entries.contains { $0.canonical == "feature/pipeline" && $0.scope == .repository })
        XCTAssertTrue(entries.contains { $0.canonical == "Package.swift" && $0.scope == .repository })
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

    @MainActor
    func testKeyboardShortcutMonitorStoresConfiguredShortcutAndTrigger() {
        let monitor = MockKeyboardShortcutMonitor()
        var triggerCount = 0

        monitor.start(shortcut: .defaultVoiceInput) {
            triggerCount += 1
        }
        monitor.trigger()
        monitor.stop()
        monitor.trigger()

        XCTAssertEqual(triggerCount, 1)
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
