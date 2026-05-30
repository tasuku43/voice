import Foundation

public enum DangerousCommandPolicy {
    public static let dangerousTerms: Set<String> = [
        "rm",
        "remove",
        "delete",
        "reset",
        "rebase",
        "force push",
        "drop",
        "truncate",
        "migrate",
        "production",
        "prod"
    ]

    public static func isDangerous(_ phrase: String) -> Bool {
        let lower = phrase.lowercased()
        return dangerousTerms.contains { lower.contains($0) }
    }
}
