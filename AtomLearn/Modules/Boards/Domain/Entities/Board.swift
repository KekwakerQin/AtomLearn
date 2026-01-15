// Модель доски (Board)

import Foundation

struct Board: Hashable {
    let id: String              // ID документа
    let title: String           // Название доски
    let description: String     // Описание доски
    let ownerUID: String        // UID владельца
    let createdAt: Date         // серверное время (serverTimestamp)
    let lastActivityAt: Date?   // Last action in Board: Add, Study, Delete etc
}
