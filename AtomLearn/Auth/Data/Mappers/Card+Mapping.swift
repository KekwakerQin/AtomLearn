import FirebaseFirestore

extension Card {
    // Парсер Firestore-словаря в доменную модель (без крэшей)
    static func initFromFirestore(id: String, data: [String: Any]) -> Card? {
        // Обязательные поля — без них карточки нет
        guard
            let boardId = data["boardId"] as? String,
            let ownerId = data["ownerId"] as? String,
            let front = data["front"] as? String,
            let back  = data["back"] as? String
        else { return nil }

        // Основные атрибуты
        let type = (data["type"] as? String).flatMap(Card.ContentType.init(rawValue:)) ?? .text
        let language = data["language"] as? String ?? "ru" // По умолчанию — русский
        let tags = data["tags"] as? [String] ?? []

        // Публикация и видимость
        let status = (data["status"] as? String).flatMap(Card.Status.init(rawValue:)) ?? .published
        let visibility = (data["visibility"] as? String).flatMap(Card.Visibility.init(rawValue:)) ?? .private

        // Доп. параметры карточки
        let difficulty = data["difficulty"] as? Int
        let hints = data["hints"] as? [String]

        // Медиа (если есть)
        var media: Card.Media?
        if let m = data["media"] as? [String: Any] {
            media = Card.Media(
                imageURL: (m["imageURL"] as? String).flatMap(URL.init(string:)),
                audioURL: (m["audioURL"] as? String).flatMap(URL.init(string:)),
                thumbURL: (m["thumbURL"] as? String).flatMap(URL.init(string:)),
                durationSec: m["durationSec"] as? Double
            )
        }

        // Источник карточки (ручной/импорт)
        var source: Card.Source?
        if let s = data["source"] as? [String: Any],
           let kindStr = s["kind"] as? String {
            source = Card.Source(
                kind: Card.SourceKind(rawValue: kindStr) ?? .manual,
                ref: s["ref"] as? String
            )
        }

        // Статистика ответов
        let rs = data["reviewStats"] as? [String: Any]
        let reviewStats = ReviewStats(
            correct: rs?["correct"] as? Int ?? 0,
            wrong: rs?["wrong"] as? Int ?? 0,
            lastReviewedAt: (rs?["lastReviewedAt"] as? Timestamp)?.dateValue()
        )

        // Интервальные повторения (SRS)
        let srs = data["spacedRepetition"] as? [String: Any]
        let spacing = SpacedRepetition(
            ease: srs?["ease"] as? Double ?? 2.5,
            intervalDays: srs?["intervalDays"] as? Int ?? 0,
            dueAt: (srs?["dueAt"] as? Timestamp)?.dateValue() ?? Date(),
            reps: srs?["reps"] as? Int ?? 0,
            lapses: srs?["lapses"] as? Int ?? 0
        )

        // Метрики и служебные поля
        let views = data["views"] as? Int ?? 0
        let version = data["version"] as? Int ?? 1
        let isDeleted = data["isDeleted"] as? Bool ?? false

        // Метки времени: при serverTimestamp могут быть nil → подставляем безопасные значения
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt

        // Собираем модель и возвращаем
        return Card(
            id: id,
            boardId: boardId,
            ownerId: ownerId,
            front: front,
            back: back,
            type: type,
            language: language,
            tags: tags,
            status: status,
            visibility: visibility,
            difficulty: difficulty,
            hints: hints,
            media: media,
            source: source,
            reviewStats: reviewStats,
            spacedRepetition: spacing,
            views: views,
            version: version,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
