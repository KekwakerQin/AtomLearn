import Foundation

enum FlashcardParsing {
    static func parseDrafts(from content: String) throws -> [FlashcardDraft] {
        let data = Data(content.utf8)

        // 1) Чистый массив
        if let arr = try? JSONDecoder().decode([FlashcardDraft].self, from: data) { return arr }

        // 2) Вырезаем первый JSON-массив из грязного текста
        if let r = content.range(of: #"(\[\s*\{[\s\S]*?\}\s*\])"#, options: .regularExpression) {
            let slice = String(content[r])
            if let arr = try? JSONDecoder().decode([FlashcardDraft].self, from: Data(slice.utf8)) { return arr }
        }

        // 3) Обёртка { "cards": [...] }
        if let r = content.range(of: #"\{\s*"cards"\s*:\s*\[\s*\{[\s\S]*?\}\s*\]\s*\}"#, options: .regularExpression) {
            let slice = String(content[r])
            struct Wrap: Codable { let cards: [FlashcardDraft] }
            if let w = try? JSONDecoder().decode(Wrap.self, from: Data(slice.utf8)) { return w.cards }
        }

        throw NSError(domain: "FlashcardParsing", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить карточки из ответа LLM"])
    }
}
