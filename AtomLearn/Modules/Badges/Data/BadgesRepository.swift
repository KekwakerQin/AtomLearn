import FirebaseFirestore

/// Репозиторий для загрузки бейджей из Firestore.
final class BadgesRepository: BadgesService {
    // MARK: - Dependencies
    private let collection = Firestore.firestore().collection("badges")

    // MARK: - Public API
    /// Загружает все бейджи, отсортированные по полю order.
    func fetchBadges() async throws -> [Badge] {
        let snapshot = try await collection.order(by: "order").getDocuments()
        do {
            return try snapshot.documents.map { try $0.data(as: Badge.self) }
        } catch {
            for doc in snapshot.documents {
                do { _ = try doc.data(as: Badge.self) }
                catch { print("❌ decode error for \(doc.documentID):", error) }
            }
            throw error
        }
    }
}
