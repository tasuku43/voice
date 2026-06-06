# Data model

## LocalContextModel

The local context model is the product-level container for environment-adaptive voice input. It is local structured data, not an LLM.

Initial contents:

- built-in developer vocabulary,
- repository vocabulary entries,
- source-derived terms from local agent or chat history,
- ASR-friendly recognition hints,
- post-STT spoken-form mappings,
- source metadata and scan counts,
- confidence and scope metadata.

Current code represents this with `LocalContextModel` in the App layer. It wraps `DictionaryEntry` values plus source counts and generated entry counts. `LocalContextModelDocument` persists it as versioned JSON:

- `schemaVersion`
- `model.entries`
- `model.sourceTextCounts`
- `model.generatedCandidateCount`
- `model.lastRebuiltAt`
- `model.sourceKinds`

The app rebuilds and persists this model after an explicit learning-source run. The same saved model supports two runtime uses:

```text
LocalContextModel
  -> SpeechRecognitionHints for STT contextualStrings
  -> DictionaryEntry values for post-STT normalization
```

Future local Foundation Model output may contribute to this model during education, but the model must remain inspectable and exportable as local data.

## DictionaryEntry

Represents a reusable mapping from spoken forms to a canonical written form, with ASR-first recognition hints kept separate from post-STT correction forms.

Fields:

- `id`
- `spokenForms`
- `canonical`
- `recognitionHints`
- `kind`
- `scope`
- `confidence`
- `autoApply`
- `createdAt`
- `updatedAt`

`recognitionHints` are the strings sent to Apple Speech `contextualStrings`; they should prefer the canonical output and ASR-friendly variants. `spokenForms` remain the correction-side raw phrases used by `NormalizationEngine` when ASR still returns the wrong text.

## DictionaryEntryKind

Initial kinds:

- toolName
- programmingLanguage
- command
- library
- framework
- fileName
- symbol
- productName
- projectTerm
- phrase

## DictionaryScope

Scope precedence:

```text
session > repository > user > global
```

## CorrectionCandidate

Represents a possible local context model entry extracted from local learning sources.

Fields:

- rawPhrase
- correctedPhrase
- confidence
- occurrenceCount
- suggestedScope
- dangerous
- autoApplyAllowed

## NormalizationResult

Includes:

- rawText
- correctedText
- applied corrections
- ambiguous or learned candidates
