import FirebaseFirestore

// Модель карточки (Card)
public struct Card: Hashable, Identifiable {
    public enum Status: String, Codable, CaseIterable { case draft, published, archived, flagged }
    public enum ContentType: String, Codable, CaseIterable { case text, image, audio }
    public enum Visibility: String, Codable, CaseIterable { case `private`, unlisted, `public` }
    public enum SourceKind: String, Codable, CaseIterable { case manual, ai, `import` }

    public let id: String // ID документа
    public let boardId: String // ID доски
    public let ownerId: String // ID владельца

    public var front: String // Текст лицевой стороны
    public var back: String // Текст обратной стороны
    public var type: ContentType // Тип контента (текст/изображение/аудио)
    public var language: String // Язык карточки
    public var tags: [String] // Теги карточки

    public var status: Status // Статус публикации
    public var visibility: Visibility // Видимость карточки

    public var difficulty: Int? // Сложность (Пока не придумал как)
    public var hints: [String]? // Подсказки
    public var media: Media? // Медиа (изображения, аудио и т.д.)
    public var source: Source? // Источник карточки (ручной, AI и т.д.)

    public var reviewStats: ReviewStats // Статистика повторений
    public var spacedRepetition: SpacedRepetition // Настройки интервальных повторений (SRS)

    public var views: Int // Просмотры карточки
    public var version: Int // Версия карточки
    public var isDeleted: Bool // Флаг удаления

    public let createdAt: Date // Дата создания
    public var updatedAt: Date // Дата последнего обновления

    public init(
        id: String,
        boardId: String,
        ownerId: String,
        front: String,
        back: String,
        type: ContentType = .text,
        language: String = "ru",
        tags: [String] = [],
        status: Status = .published,
        visibility: Visibility = .private,
        difficulty: Int? = nil,
        hints: [String]? = nil,
        media: Media? = nil,
        source: Source? = nil,
        reviewStats: ReviewStats = .init(correct: 0, wrong: 0, lastReviewedAt: nil),
        spacedRepetition: SpacedRepetition = .defaults,
        views: Int = 0,
        version: Int = 1,
        isDeleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.boardId = boardId
        self.ownerId = ownerId
        self.front = front
        self.back = back
        self.type = type
        self.language = language
        self.tags = tags
        self.status = status
        self.visibility = visibility
        self.difficulty = difficulty
        self.hints = hints
        self.media = media
        self.source = source
        self.reviewStats = reviewStats
        self.spacedRepetition = spacedRepetition
        self.views = views
        self.version = version
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Базовый шаблон данных для новой карточки (в Firestore-формате)
    // Удалить потом, нужен для базовых данных
    static func basic(for boardId: String, ownerId: String) -> [String: Any] {
        return [
            "boardId": boardId,
            "ownerId": ownerId,

            "front": "Новая карточка",
            "back": "Ответ...",

            "type": "text",                   // соответствует Card.ContentType.text
            "language": "ru",
            "tags": [],

            // статус и видимость — важные фильтры для индексов
            "status": "published",
            "visibility": "private",

            "difficulty": "FieldValue.delete()", // пропущено = нет значения
            "hints": [],
            "media": "FieldValue.delete()",
            "source": [
                "kind": "manual",
                "ref": "FieldValue.delete()"
            ],

            // статистика ревью
            "reviewStats": [
                "correct": 0,
                "wrong": 0,
                "lastReviewedAt": "FieldValue.delete()"
            ],

            // spaced repetition (SRS)
            "spacedRepetition": [
                "ease": 2.5,
                "intervalDays": 0,
                "dueAt": "FieldValue.serverTimestamp()",
                "reps": 0,
                "lapses": 0
            ],

            // служебные поля
            "isDeleted": false,
            "version": 1,
            "views": 0,

            // серверные таймстемпы
            "createdAt": "FieldValue.serverTimestamp()",
            "updatedAt": "FieldValue.serverTimestamp()"
        ]
    }

    // Медиа-данные карточки
    public struct Media: Codable, Hashable {
        public var imageURL: URL?
        public var audioURL: URL?
        public var thumbURL: URL?
        public var durationSec: Double?
        public init(imageURL: URL? = nil, audioURL: URL? = nil, thumbURL: URL? = nil, durationSec: Double? = nil) {
            self.imageURL = imageURL; self.audioURL = audioURL; self.thumbURL = thumbURL; self.durationSec = durationSec
        }
    }

    // Источник карточки
    public struct Source: Codable, Hashable {
        public var kind: SourceKind
        public var ref: String?
        public init(kind: SourceKind, ref: String? = nil) { self.kind = kind; self.ref = ref }
    }
}

// Статистика повторений (результаты изучения)
public struct ReviewStats: Codable, Hashable {
    public var correct: Int
    public var wrong: Int
    public var lastReviewedAt: Date?
    public init(correct: Int, wrong: Int, lastReviewedAt: Date?) {
        self.correct = correct; self.wrong = wrong; self.lastReviewedAt = lastReviewedAt
    }
}

// Интервальные повторения (SRS)
public struct SpacedRepetition: Codable, Hashable {
    public var ease: Double // 1.3 ... 2.7 (FSRS/SM-2 like)
    public var intervalDays: Int
    public var dueAt: Date
    public var reps: Int
    public var lapses: Int

    public init(ease: Double, intervalDays: Int, dueAt: Date, reps: Int = 0, lapses: Int = 0) {
        self.ease = ease; self.intervalDays = intervalDays; self.dueAt = dueAt; self.reps = reps; self.lapses = lapses
    }

    public static let defaults = SpacedRepetition(ease: 2.5, intervalDays: 0, dueAt: Date())
}
