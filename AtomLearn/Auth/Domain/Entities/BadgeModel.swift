import FirebaseFirestore

struct Badge: Codable, Identifiable {
    var id: String?
    var name: String
    var description: String
    var collection: String
    var imagePath: String
    var order: Int?
}

extension Badge {
    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        guard
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let collection = data["collection"] as? String,
            let imagePath = data["imagePath"] as? String
        else { return nil }

        // order может быть числом или строкой
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

final class BadgeRepository {
    private let col = Firestore.firestore().collection("badges")

    func fetchAll() async throws -> [Badge] {
        let snapshot = try await col.order(by: "order").getDocuments()
        do {
            return try snapshot.documents.map { try $0.data(as: Badge.self) }
        } catch {
            // полезно увидеть, какая именно проблема у первого нераспарсенного дока
            for doc in snapshot.documents {
                do { _ = try doc.data(as: Badge.self) }
                catch { print("❌ decode error for \(doc.documentID):", error) }
            }
            throw error
        }
    }
}
