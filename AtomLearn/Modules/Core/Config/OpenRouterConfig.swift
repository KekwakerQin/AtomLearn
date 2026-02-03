import Foundation

enum OpenRouterConfig {
    private static func readString(_ key: String) -> String? {
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let unquoted = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if !unquoted.isEmpty { return unquoted }
        }

        if let env = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            return env.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    static var apiKey: String {
        guard let key = readString("OPENROUTER_API_KEY"), !key.isEmpty else {
            assertionFailure("[LOG:ERROR] OPENROUTER_API_KEY не найден")
            return ""
        }
        return key
    }

    static var baseURL: URL {
        if let raw = readString("OPENROUTER_BASE_URL"), let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    }

    static var appTitle: String { readString("OPENROUTER_APP_TITLE") ?? "AtomLearn" }

    static var siteURL: String? { readString("OPENROUTER_SITE_URL") }
}
