# Repository Vocabulary Session

Purpose: improve bounded repository vocabulary extraction.

Read:
- `docs/contracts/normalization.md`
- `src/VoiceAgentInputCore/App/DictionaryContextLoadingUseCase.swift`
- `src/VoiceAgentInputCore/App/RepositoryVocabularyUseCase.swift`
- `src/VoiceAgentInputCore/Infra/GitRepositoryContextProvider.swift`

May touch:
- Repository context providers, vocabulary use cases, tests.

Avoid:
- Speech, preview UI, output adapters.

Contract:
- Use bounded tracked files only.
- Do not perform broad uncontrolled recursive scans.

Tests:
- `swift test --filter UseCaseAndRepositoryTests/testDictionaryContextLoadingUseCaseCombinesSeedLocalAndRepositoryVocabulary`
- `swift test --filter UseCaseAndRepositoryTests/testGitRepositoryContextProviderReadsBoundedTrackedVocabularyFiles`
- `make check`

Done:
- Repository entries remain repository-scoped and bounded.
