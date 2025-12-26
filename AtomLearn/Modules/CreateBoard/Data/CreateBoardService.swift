import FirebaseFirestore

protocol CreateBoardServiceProtocol {
    /// Создать борд в Firestore
    func createBoard(
        title: String,
        ownerUID: String
    ) async throws
}

final class CreateBoardService: CreateBoardServiceProtocol {

    // MARK: - Dependencies
    private let db = Firestore.firestore()

    // MARK: - Public API
    func createBoard(
        title: String,
        ownerUID: String
    ) async throws {

        let id = UUID().uuidString

        let data: [String: Any] = [
            "id": id,
            "title": title,
            "ownerUID": ownerUID,
            "createdAt": Timestamp(),
            "lastActivityAt": Timestamp()
        ]

        try await db
            .collection("boards")
            .document(id)
            .setData(data)
    }
}
