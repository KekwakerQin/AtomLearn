import Foundation

final class ManuallyCreateCardsService: ManuallyCreateCardsServiceProtocol {
    
    var repository: ManuallyCreateCardsRepositoryProtocol
    
    init(repository: ManuallyCreateCardsRepository) {
        self.repository = repository
    }
    
    func addCards(boardId: String, ownerId: String, cards: [ManuallyCreateCardsPayload]) async throws {
        try await repository.addCards(boardId: boardId, ownerId: ownerId, cards: cards)
    }
}
