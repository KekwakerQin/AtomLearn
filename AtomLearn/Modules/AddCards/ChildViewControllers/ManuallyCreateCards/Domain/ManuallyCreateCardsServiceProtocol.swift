import Foundation

protocol ManuallyCreateCardsServiceProtocol {
    // Saves cards into a board.
    func addCards(boardId: String, ownerId: String, cards: [ManuallyCreateCardsPayload]) async throws
}
