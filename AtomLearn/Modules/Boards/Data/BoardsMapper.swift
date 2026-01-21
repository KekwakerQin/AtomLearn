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

        // createdAt — Timestamp → Date (fallback только если вообще нет поля)
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            ?? Date.distantPast

        // lastActivityAt — optional, fallback на createdAt
        let lastActivityAt = (data["lastActivityAt"] as? Timestamp)?.dateValue()
            ?? createdAt

        // Access lists (safe-cast both [String] and [Any] -> [String])
        let toStringArray: (Any?) -> [String] = { value in
            if let arr = value as? [String] { return arr }
            if let anyArr = value as? [Any] { return anyArr.compactMap { $0 as? String } }
            return []
        }

        let memberUIDs = toStringArray(data["memberUIDs"])
        let editorUIDs = toStringArray(data["editorUIDs"])
        let viewerUIDs = toStringArray(data["viewerUIDs"]) 

        return Board(
            id: doc.documentID,
            title: title,
            description: data["description"] as? String ?? "",
            ownerUID: ownerUID,
            memberUIDs: memberUIDs,
            editorUIDs: editorUIDs,
            viewerUIDs: viewerUIDs,
            createdAt: createdAt,
            lastActivityAt: lastActivityAt
        )
    }
}
