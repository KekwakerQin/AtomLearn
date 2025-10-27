import FirebaseFirestore

struct Card {
    let id: String
    let boardId: String
    let ownerId: String
    let front: String
    let back: String
    let type: String
    let language: String
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    let isDeleted: Bool
    let version: Int
    let views: Int

    init?(id: String, data: [String: Any]) {
        // обязательные минимум
        guard
            let boardId = data["boardId"] as? String,
            let ownerId = data["ownerId"] as? String
        else { return nil }

        self.id = id
        self.boardId = boardId
        self.ownerId = ownerId
        self.front = data["front"] as? String ?? ""          // мягкие дефолты
        self.back = data["back"] as? String ?? ""
        self.type = data["type"] as? String ?? "basic"
        self.language = data["language"] as? String ?? "ru"
        self.tags = data["tags"] as? [String] ?? []
        self.isDeleted = data["isDeleted"] as? Bool ?? false
        self.version = data["version"] as? Int ?? 1
        self.views = data["views"] as? Int ?? 0

        // createdAt/updatedAt могли отсутствовать в старых доках — подставляем now
        let now = Date()
        if let ts = data["createdAt"] as? Timestamp { self.createdAt = ts.dateValue() } else { self.createdAt = now }
        if let ts = data["updatedAt"] as? Timestamp { self.updatedAt = ts.dateValue() } else { self.updatedAt = now }
    }

    static func basic(for boardId: String, ownerId: String) -> [String: Any] {
        return [
            "boardId": boardId,
            "ownerId": ownerId,
            "front": "Новая карточка",
            "back": "Ответ...",
            "type": "basic",
            "language": "ru",
            "tags": [],
            // timestamps — серверные, чтобы поле точно было и для сортировки
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "isDeleted": false,
            "version": 1,
            "views": 0,
            // не кладём NSNull — просто опускаем поля, если пусто
            "srs": [
                "level": 0,
                "easiness": 2.5,
                "intervalDays": 0,
                "repetitions": 0
            ],
            "createdBy": "user"
        ]
    }
}
