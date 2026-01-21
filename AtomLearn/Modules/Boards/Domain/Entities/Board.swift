// Модель доски (Board)

import Foundation

struct Board: Hashable {
    let id: String              // ID документа
    let title: String           // Название доски
    let description: String     // Описание доски
    let ownerUID: String        // UID владельца
    let memberUIDs: [String]
    let editorUIDs: [String]  
    let viewerUIDs: [String]
    let createdAt: Date         // серверное время (serverTimestamp)
    let lastActivityAt: Date?   // Last action in Board: Add, Study, Delete etc
}

extension Board {
    var activitySortDate: Date {
        lastActivityAt ?? createdAt
    }
}
