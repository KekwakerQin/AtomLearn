import FirebaseFirestore

/// Модель бейджа (ачивки).
struct Badge: Codable, Identifiable {
    /// Уникальный ID документа.
    var id: String?
    /// Название бейджа.
    var name: String
    /// Описание бейджа.
    var description: String
    /// Коллекция, к которой относится.
    var collection: String
    /// Путь к изображению в Storage.
    var imagePath: String
    /// Порядок отображения (опционально).
    var order: Int?
}

extension Badge {
    /// Инициализирует модель из документа Firestore.
    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        guard
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let collection = data["collection"] as? String,
            let imagePath = data["imagePath"] as? String
        else { return nil }

        var ord: Int? = nil
        if let n = data["order"] as? Int {
            ord = n
        } else if let s = data["order"] as? String, let n = Int(s) {
            ord = n
        }

        self.id = doc.documentID
        self.name = name
        self.description = description
        self.collection = collection
        self.imagePath = imagePath
        self.order = ord
    }
}
