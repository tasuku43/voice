# Data model

## DictionaryEntry

Represents a reusable mapping from spoken forms to a canonical written form.

Fields:

- `id`
- `spokenForms`
- `canonical`
- `kind`
- `scope`
- `confidence`
- `autoApply`
- `createdAt`
- `updatedAt`

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
