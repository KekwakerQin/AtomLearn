import Supabase
import Foundation

// Конфигурация Supabase: URL, ключи и бакеты
enum SupabaseConfig {
    // Чтение строки из Info.plist или ENV
    private static func readString(_ key: String) -> String? {
        // Пытаемся прочитать из Info.plist
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)

            let unquoted = s.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if !unquoted.isEmpty { return unquoted }
        }

        // Если не найдено — читаем из переменных окружения
        if let env = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            return env.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    // URL проекта Supabase
    static let url: URL = {
        let host = readString("SUPABASE_URL")
        let fullString = "https://" + (host ?? "")
        guard let url = URL(string: fullString) else {
            fatalError("[LOG:ERROR] Некорректный Supabase URL: \(fullString)")
        }
        return url
    }()
    
    // Анонимный ключ (anon key)
    static var anonKey: String {
        guard let key = readString("SUPABASE_ANON"), !key.isEmpty else {
            assertionFailure("[LOG:ERROR] SUPABASE_ANON не найден")
            fatalError("[LOG:ERROR] Отсутствует ключ SUPABASE_ANON")
        }
        return key
    }

    // Имя бакета по умолчанию
    static var bucket: String { readString("SUPABASE_BUCKET") ?? "icons" }
    // Путь к тестовому файлу (например, логотип)
    static var knownPath: String { readString("SUPABASE_KNOWN_PATH") ?? "logo.png" }
}
