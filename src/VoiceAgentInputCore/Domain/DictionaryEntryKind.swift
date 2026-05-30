import Foundation

public enum DictionaryEntryKind: String, Codable, CaseIterable, Sendable {
    case toolName
    case programmingLanguage
    case command
    case library
    case framework
    case fileName
    case symbol
    case productName
    case projectTerm
    case phrase
}
