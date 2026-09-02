import Foundation

public enum TodoSearch {
    public static func matches(title: String, query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return true
        }

        return title.range(
            of: normalizedQuery,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) != nil
    }
}
