import FirebaseFirestore

// Модель бейджа (ачивки)
struct Badge: Codable, Identifiable {
    var id: String?              // Уникальный ID документа
    var name: String             // Название бейджа
    var description: String      // Описание бейджа
    var collection: String       // Коллекция, к которой относится
    var imagePath: String        // Путь к изображению в Storage
    var order: Int?              // Порядок отображения (опционально)
}

// Инициализация из Firestore-документа
extension Badge {
    init?(doc: DocumentSnapshot) {
        // Достаём словарь данных из документа
        guard let data = doc.data() else { return nil }
        guard
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let collection = data["collection"] as? String,
            let imagePath = data["imagePath"] as? String
        else { return nil }

        // Поле order может быть числом или строкой — парсим безопасно
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

// Репозиторий для загрузки бейджей из Firestore
final class BadgeRepository {
    private let col = Firestore.firestore().collection("badges")

    // Загружаем все бейджи, отсортированные по полю order
    func fetchAll() async throws -> [Badge] {
        let snapshot = try await col.order(by: "order").getDocuments()
        do {
            return try snapshot.documents.map { try $0.data(as: Badge.self) }
        } catch {
            // Если ошибка — выводим проблемные документы в консоль для отладки
            for doc in snapshot.documents {
                do { _ = try doc.data(as: Badge.self) }
                catch { print("❌ decode error for \(doc.documentID):", error) }
            }
            throw error
        }
    }
}
