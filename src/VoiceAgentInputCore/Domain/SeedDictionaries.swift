import Foundation

public enum SeedDictionaries {
    public static let codingAgentEntries: [DictionaryEntry] = [
        DictionaryEntry(
            spokenForms: ["クロードコード", "くらうどこーど", "くらのコード"],
            canonical: "Claude Code",
            kind: .toolName,
            scope: .global,
            confidence: 0.95,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["こーでっくす", "コーデックス"],
            canonical: "Codex",
            kind: .toolName,
            scope: .global,
            confidence: 0.95,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["カーソル", "かーそる"],
            canonical: "Cursor",
            kind: .toolName,
            scope: .global,
            confidence: 0.9,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["タイプスクリプト", "たいぷすくりぷと"],
            canonical: "TypeScript",
            kind: .programmingLanguage,
            scope: .global,
            confidence: 0.95,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["スイフト", "すいふと"],
            canonical: "Swift",
            kind: .programmingLanguage,
            scope: .global,
            confidence: 0.9,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["ぴーえぬぴーえむ", "ピーエヌピーエム"],
            canonical: "pnpm",
            kind: .command,
            scope: .global,
            confidence: 0.9,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["えぬぴーえむ", "エヌピーエム"],
            canonical: "npm",
            kind: .command,
            scope: .global,
            confidence: 0.85,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["ぎっとはぶ", "ギットハブ"],
            canonical: "GitHub",
            kind: .toolName,
            scope: .global,
            confidence: 0.9,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["えむしーぴー", "エムシーピー"],
            canonical: "MCP",
            kind: .framework,
            scope: .global,
            confidence: 0.9,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["ブランチ"],
            canonical: "branch",
            kind: .projectTerm,
            scope: .global,
            confidence: 0.8,
            autoApply: true
        ),
        DictionaryEntry(
            spokenForms: ["エラー"],
            canonical: "error",
            kind: .projectTerm,
            scope: .global,
            confidence: 0.8,
            autoApply: true
        )
    ]
}
