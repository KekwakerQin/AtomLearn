import FirebaseFirestore

enum BoardMapper {

    static func from(doc: DocumentSnapshot) -> Board? {
        let data = doc.data() ?? [:]

        // Обязательные поля
        guard
            let title = data["title"] as? String,
            let ownerUID = data["ownerUID"] as? String
        else {
            print("[WARN] Failed to parse board \(doc.documentID)")
            print("[WARN] Raw data:", data)
            return nil
        }

        // createdAt — Timestamp → Date
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            ?? Date.distantPast

        // lastActivityAt — ОПЦИОНАЛЬНО
        let lastActivityAt = (data["lastActivityAt"] as? Timestamp)?.dateValue()

        return Board(
            id: doc.documentID,
            title: title,
            description: data["description"] as? String ?? "",
            ownerUID: ownerUID,
            createdAt: createdAt,
            lastActivityAt: lastActivityAt
        )
    }
}
