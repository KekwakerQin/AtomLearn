import FirebaseFirestore

protocol AddCardsServiceProtocol {
    func addCard(boardId: String, ownerId: String) async throws
}

final class AddCardsService: AddCardsServiceProtocol {

    private let db = Firestore.firestore()

    func addCard(boardId: String, ownerId: String) async throws {
        let data = Card.basic(for: boardId, ownerId: ownerId)

        try await db
            .collection("boards")
            .document(boardId)
            .collection("cards")
            .addDocument(data: data)
    }
}
