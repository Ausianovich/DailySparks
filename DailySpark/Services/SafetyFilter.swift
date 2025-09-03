import Foundation

enum SafetyFilter {
    // Very light heuristic; relies mainly on system prompts. Expand as needed.
    static func isUnsafe(_ text: String) -> Bool {
        let lower = text.lowercased()
        let banned = ["politic", "election", "religion", "sex ", "nsfw", "violence", "illegal"]
        return banned.contains { lower.contains($0) }
    }

    static func filterSparks(_ raw: String) -> [String] {
        // Split by lines and keep non-empty
        let lines = raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.filter { !isUnsafe($0) }
    }
}

