import Foundation
import FirebaseFirestore

final class CardsRepository: CardsService {
    private let db = Firestore.firestore()

    func addCards(
        boardId: String,
        ownerId: String,
        drafts: [FlashcardDraft],
        sourceKind: Card.SourceKind,
        sourceRef: String?
    ) async throws {
        guard !drafts.isEmpty else { return }

        let cardsRef = db.collection("boards").document(boardId).collection("cards")
        let batch = db.batch()

        for draft in drafts {
            let card = FlashcardMapping.toCard(
                boardId: boardId,
                ownerId: ownerId,
                draft: draft,
                sourceKind: sourceKind,
                sourceRef: sourceRef
            )
            let data = FlashcardMapping.toFirestoreData(card)
            let doc = cardsRef.document()
            batch.setData(data, forDocument: doc)
        }

        try await batch.commit()
    }
}
