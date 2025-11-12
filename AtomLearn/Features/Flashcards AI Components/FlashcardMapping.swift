import Foundation
import FirebaseFirestore

enum FlashcardMapping {

    // Делаем локальную Card из драфта — удобно для предпросмотра/редактирования до записи в БД.
    static func toCard(
        boardId: String,
        ownerId: String,
        draft: FlashcardDraft,
        now: Date = Date()
    ) -> Card {
        Card(
            id: UUID().uuidString,
            boardId: boardId,
            ownerId: ownerId,
            front: draft.front,
            back: draft.back,
            type: .text,            // TODO: если будут медиа — тут логика выбора
            language: "ru",         // TODO: подставь язык из контекста
            tags: draft.tags,
            status: .published,     // TODO: можно начинать с .draft
            visibility: .private,   // TODO: политика видимости
            difficulty: nil,
            hints: nil,
            media: nil,
            source: .init(kind: .ai, ref: "openrouter"), // источник — AI
            reviewStats: .init(correct: 0, wrong: 0, lastReviewedAt: nil),
            spacedRepetition: .defaults,
            views: 0,
            version: 1,
            isDeleted: false,
            createdAt: now,
            updatedAt: now
        )
    }

    /// Превращаем Card в Firestore-словарь по твоей схеме.
    static func toFirestoreData(_ card: Card) -> [String: Any] {
        var data: [String: Any] = [
            "boardId": card.boardId,
            "ownerId": card.ownerId,
            "front": card.front,
            "back": card.back,
            "type": card.type.rawValue,
            "language": card.language,
            "tags": card.tags,
            "status": card.status.rawValue,
            "visibility": card.visibility.rawValue,
            "reviewStats": [
                "correct": card.reviewStats.correct,
                "wrong": card.reviewStats.wrong
            ],
            "spacedRepetition": [
                "ease": card.spacedRepetition.ease,
                "intervalDays": card.spacedRepetition.intervalDays,
                // важно: при создании пусть сервер выставит dueAt
                "dueAt": FieldValue.serverTimestamp(),
                "reps": card.spacedRepetition.reps,
                "lapses": card.spacedRepetition.lapses
            ],
            "isDeleted": card.isDeleted,
            "version": card.version,
            "views": card.views,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // Опционали — только если есть смысл
        if let diff = card.difficulty { data["difficulty"] = diff }
        if let hints = card.hints   { data["hints"] = hints }
        if let media = card.media {
            var m: [String: Any] = [:]
            if let u = media.imageURL { m["imageURL"] = u.absoluteString }
            if let u = media.audioURL { m["audioURL"] = u.absoluteString }
            if let u = media.thumbURL { m["thumbURL"] = u.absoluteString }
            if let d = media.durationSec { m["durationSec"] = d }
            data["media"] = m
        }
        if let src = card.source {
            var s: [String: Any] = ["kind": src.kind.rawValue]
            if let ref = src.ref { s["ref"] = ref }
            data["source"] = s
        }
        return data
    }
}
