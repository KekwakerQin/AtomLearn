import Foundation

protocol ManuallyCreateCardsRepositoryProtocol {
    // Persists cards to data source
    func addCards(boardId: String, ownerId: String, cards: [ManuallyCreateCardsPayload]) async throws 
}
