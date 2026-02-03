import Foundation

struct StudyCardSnapshot: Codable, Equatable, Identifiable {
    let id: String
    let front: String
    let back: String
}

struct StudySessionState: Codable, Equatable {
    enum Order: String, Codable {
        case recent
        case shuffle
    }

    var boardId: String
    var boardTitle: String?
    var order: Order
    var cards: [StudyCardSnapshot]
    var currentIndex: Int
    var hardCards: [StudyCardSnapshot]
    var round: Int
    var isCompleted: Bool
    var correctCount: Int
    var wrongCount: Int

    static func new(boardId: String, boardTitle: String?, order: Order, cards: [StudyCardSnapshot]) -> StudySessionState {
        StudySessionState(
            boardId: boardId,
            boardTitle: boardTitle,
            order: order,
            cards: cards,
            currentIndex: 0,
            hardCards: [],
            round: 1,
            isCompleted: false,
            correctCount: 0,
            wrongCount: 0
        )
    }
}
