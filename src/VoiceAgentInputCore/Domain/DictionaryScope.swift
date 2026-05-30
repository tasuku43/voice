import Foundation

public enum DictionaryScope: String, Codable, CaseIterable, Comparable, Sendable {
    case global
    case user
    case repository
    case session

    public var precedence: Int {
        switch self {
        case .global: return 0
        case .user: return 1
        case .repository: return 2
        case .session: return 3
        }
    }

    public static func < (lhs: DictionaryScope, rhs: DictionaryScope) -> Bool {
        lhs.precedence < rhs.precedence
    }
}
