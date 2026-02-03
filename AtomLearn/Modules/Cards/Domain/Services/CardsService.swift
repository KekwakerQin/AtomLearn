import Foundation

protocol CardsService {
    func addCards(
        boardId: String,
        ownerId: String,
        drafts: [FlashcardDraft],
        sourceKind: Card.SourceKind,
        sourceRef: String?
    ) async throws
}
