# Data model

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

Represents a possible learned dictionary entry extracted from user edits.

Fields:

- rawPhrase
- correctedPhrase
- confidence
- occurrenceCount
- suggestedScope
- approved
- rejected
- dangerous
- autoApplyAllowed

## NormalizationResult

Includes:

- rawText
- correctedText
- applied corrections
- ambiguous or learned candidates
