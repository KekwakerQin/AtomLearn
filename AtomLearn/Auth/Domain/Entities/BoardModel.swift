import Foundation
import FirebaseFirestore

// Модель доски (Board)
struct Board: Hashable {
    let id: String              // ID документа
    let title: String           // Название доски
    let description: String     // Описание доски
    let ownerUID: String        // UID владельца
    let createdAt: Date         // серверное время (serverTimestamp)
    let createdAtClient: Date   // локальное время клиента (при создании)
}

// Расширение: инициализация модели из Firestore
extension Board {
    // Инициализация из снимка документа
    init?(doc: DocumentSnapshot) {
        // Достаём данные документа
        let data = doc.data() ?? [:]
        // Проверяем обязательные поля
        guard
            let title = data["title"] as? String,
            let ownerUID = data["ownerUID"] as? String
        else {
            print("[LOG:WARN] Board parse failed for \(doc.documentID)")
            return nil
        }

        self.id = doc.documentID
        self.title = title
        self.description = data["description"] as? String ?? ""
        self.ownerUID = ownerUID

        // Серверное время (serverTimestamp)
        if let ts = data["createdAt"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = Date.distantPast
        }

        // Локальное время клиента
        if let tsClient = data["createdAtClient"] as? Timestamp {
            self.createdAtClient = tsClient.dateValue()
        } else {
            // если поля нет (старые документы) — подстрахуемся серверным/текущим временем
            self.createdAtClient = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        }
    }

    // Инициализация из словаря (для локальных данных)
    init?(id: String, data: [String: Any]) {
        guard
            let title = data["title"] as? String,
            let ownerUID = data["ownerUID"] as? String
        else {
            print("[LOG:WARN] Failed to parse board: \(id)")
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
        let createdAtClient = (data["createdAtClient"] as? Timestamp)?.dateValue()
            ?? (data["createdAt"] as? Timestamp)?.dateValue()
            ?? Date()

        self.init(
            id: id,
            title: title,
            description: data["description"] as? String ?? "",
            ownerUID: ownerUID,
            createdAt: createdAt,
            createdAtClient: createdAtClient
        )
    }
}
